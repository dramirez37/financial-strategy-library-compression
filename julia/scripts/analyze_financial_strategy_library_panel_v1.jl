module AnalyzeFinancialStrategyLibraryPanelV1

using Dates
using Parquet
using Printf
using SHA: sha256
using StrategyInnovation
using Tables
using TOML

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV1.jl"))
using .FinancialStrategyLibraryPanelV1
using .FinancialStrategyLibraryPanelV1.FinancialPanelParquet

export audit_ready,
       main,
       run_analysis

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const ALGORITHM_IDS = collect(FinancialStrategyLibraryPanelV1.ALGORITHM_IDS)
const SELECTED_ID_SEPARATOR = '\u001f'
const ANALYSIS_THREAD_COUNT = 8

const ALGORITHM_SCHEMA = (
    origin_id = String,
    decision_year = Int64,
    library_id = String,
    schedule_id = String,
    algorithm_id = String,
    instance_status = String,
    structural_result_sha256 = String,
    postdecision_result_sha256 = String,
    exact_reference_available = Bool,
    source_active_strategy_count = Union{Missing,Int64},
    frontier_requirement_count = Union{Missing,Int64},
    module_requirement_count = Union{Missing,Int64},
    tagged_requirement_count = Union{Missing,Int64},
    coverage_density_exact = Union{Missing,String},
    coverage_density = Union{Missing,Float64},
    duplicate_coverage_count = Union{Missing,Int64},
    unique_carrier_count = Union{Missing,Int64},
    variables_before_preprocessing = Union{Missing,Int64},
    variables_after_preprocessing = Union{Missing,Int64},
    requirements_before_preprocessing = Union{Missing,Int64},
    requirements_after_preprocessing = Union{Missing,Int64},
    forced_strategy_count = Union{Missing,Int64},
    dominance_reductions = Union{Missing,Int64},
    preprocessing_fixed_point_iterations = Union{Missing,Int64},
    source_burden_exact = Union{Missing,String},
    source_burden = Union{Missing,Float64},
    applicable = Bool,
    status = String,
    candidate_returned = Bool,
    selected_active_strategy_count = Union{Missing,Int64},
    selected_burden_exact = Union{Missing,String},
    selected_burden = Union{Missing,Float64},
    benchmark_burden_exact = Union{Missing,String},
    benchmark_burden = Union{Missing,Float64},
    absolute_burden_gap_exact = Union{Missing,String},
    absolute_burden_gap = Union{Missing,Float64},
    relative_burden_gap_exact = Union{Missing,String},
    relative_burden_gap = Union{Missing,Float64},
    optimum_attained = Union{Missing,Bool},
    wall_clock_ns = String,
    wall_clock_seconds = Union{Missing,Float64},
    termination_status = String,
    primal_status = String,
    dual_status = String,
    solver_claimed_optimal = Bool,
    best_bound = Union{Missing,Float64},
    reported_gap = Union{Missing,Float64},
    mip_node_count = Union{Missing,Float64},
    dp_state_count = Union{Missing,Float64},
    frontier_checks = Union{Missing,Float64},
    closure_checks = Union{Missing,Float64},
    complete_scans = Union{Missing,Float64},
    multi_start_improvement_exact = Union{Missing,String},
    multi_start_improvement = Union{Missing,Float64},
    exact_mandatory_retention = Union{Missing,Bool},
    exact_tagged_coverage = Union{Missing,Bool},
    exact_frontier_preservation = Union{Missing,Bool},
    exact_closure_preservation = Union{Missing,Bool},
    exact_feasible = Union{Missing,Bool},
    selected_active_ids = String,
    selected_identity_sha256 = String,
    postdecision_available = Bool,
    belief_losses_exact = String,
    mean_belief_loss_exact = Union{Missing,String},
    mean_belief_loss = Union{Missing,Float64},
    no_loss_share_exact = Union{Missing,String},
    no_loss_share = Union{Missing,Float64},
    identity_persistence_exact = Union{Missing,String},
    identity_persistence = Union{Missing,Float64},
    source_security_delisting_count = Union{Missing,Int64},
)

const SUMMARY_SCHEMA = (
    library_id = String,
    schedule_id = String,
    algorithm_id = String,
    registered_instance_count = Int64,
    successful_instance_count = Int64,
    failure_instance_count = Int64,
    applicable_count = Int64,
    candidate_count = Int64,
    exactly_feasible_count = Int64,
    exact_reference_count = Int64,
    optimum_attainment_count = Int64,
    optimum_attainment_frequency = Union{Missing,Float64},
    absolute_gap_count = Int64,
    absolute_gap_mean = Union{Missing,Float64},
    absolute_gap_median = Union{Missing,Float64},
    absolute_gap_q25 = Union{Missing,Float64},
    absolute_gap_q75 = Union{Missing,Float64},
    absolute_gap_p90 = Union{Missing,Float64},
    absolute_gap_max = Union{Missing,Float64},
    relative_gap_count = Int64,
    relative_gap_mean = Union{Missing,Float64},
    relative_gap_median = Union{Missing,Float64},
    relative_gap_q25 = Union{Missing,Float64},
    relative_gap_q75 = Union{Missing,Float64},
    relative_gap_p90 = Union{Missing,Float64},
    relative_gap_max = Union{Missing,Float64},
    runtime_count = Int64,
    runtime_mean_seconds = Union{Missing,Float64},
    runtime_median_seconds = Union{Missing,Float64},
    runtime_q25_seconds = Union{Missing,Float64},
    runtime_q75_seconds = Union{Missing,Float64},
    runtime_p90_seconds = Union{Missing,Float64},
    runtime_max_seconds = Union{Missing,Float64},
    mip_node_count = Int64,
    mip_nodes_median = Union{Missing,Float64},
    dp_state_count = Int64,
    dp_states_median = Union{Missing,Float64},
    exact_evaluation_count = Int64,
    exact_evaluations_median = Union{Missing,Float64},
    multistart_improvement_count = Int64,
    multistart_improvement_mean = Union{Missing,Float64},
    postdecision_available_count = Int64,
    mean_belief_loss_mean = Union{Missing,Float64},
    no_loss_share_mean = Union{Missing,Float64},
)

const OVERLAP_SCHEMA = (
    origin_id = String,
    decision_year = Int64,
    library_id = String,
    schedule_id = String,
    algorithm_id = String,
    comparison_type = String,
    left_id = String,
    right_id = String,
    available = Bool,
    intersection_count = Union{Missing,Int64},
    union_count = Union{Missing,Int64},
    jaccard = Union{Missing,Float64},
)

const INSTANCE_SCHEMA = (
    origin_id = String,
    decision_year = Int64,
    library_id = String,
    schedule_id = String,
    instance_status = String,
    exact_reference_available = Bool,
    source_active_strategy_count = Union{Missing,Int64},
    frontier_requirement_count = Union{Missing,Int64},
    module_requirement_count = Union{Missing,Int64},
    tagged_requirement_count = Union{Missing,Int64},
    coverage_density_exact = Union{Missing,String},
    coverage_density = Union{Missing,Float64},
    duplicate_coverage_count = Union{Missing,Int64},
    unique_carrier_count = Union{Missing,Int64},
    forced_strategy_count = Union{Missing,Int64},
    dominance_reductions = Union{Missing,Int64},
    variables_before_preprocessing = Union{Missing,Int64},
    variables_after_preprocessing = Union{Missing,Int64},
    variable_reduction_fraction = Union{Missing,Float64},
    requirements_before_preprocessing = Union{Missing,Int64},
    requirements_after_preprocessing = Union{Missing,Int64},
    requirement_reduction_fraction = Union{Missing,Float64},
    preprocessing_empty_residual = Union{Missing,Bool},
    source_burden_exact = Union{Missing,String},
    source_burden = Union{Missing,Float64},
    benchmark_burden_exact = Union{Missing,String},
    benchmark_burden = Union{Missing,Float64},
    certified_burden_saving_fraction = Union{Missing,Float64},
)

const AGREEMENT_SCHEMA = (
    origin_id = String,
    decision_year = Int64,
    library_id = String,
    schedule_id = String,
    instance_status = String,
    exact_reference_available = Bool,
    dp_candidate_returned = Bool,
    enumeration_candidate_returned = Bool,
    mip_candidate_returned = Bool,
    dp_burden_exact = Union{Missing,String},
    enumeration_burden_exact = Union{Missing,String},
    mip_burden_exact = Union{Missing,String},
    dp_enumeration_objective_agreement = Union{Missing,Bool},
    mip_exact_objective_agreement = Union{Missing,Bool},
    mip_solver_claimed_optimal = Bool,
    mip_solver_status_used_as_exact_proof = Bool,
    dp_enumeration_optimizer_identity_agreement = Union{Missing,Bool},
    mip_exact_optimizer_identity_agreement = Union{Missing,Bool},
)

const CARRIER_SCHEMA = (
    origin_id = String,
    decision_year = Int64,
    library_id = String,
    schedule_id = String,
    requirement_index = Int64,
    requirement_kind = String,
    carrier_count = Int64,
    unique_carrier = Bool,
)

_utc_now() = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
_sha256_text(value) = bytes2hex(sha256(codeunits(value)))

function _paths(config)
    local_results = joinpath(REPOSITORY_ROOT, String(config["paths"]["local_results_root"]))
    analysis = joinpath(local_results, "analysis")
    return (
        local_results,
        structural = joinpath(local_results, "structural"),
        postdecision = joinpath(local_results, "postdecision"),
        instances = joinpath(local_results, "instances"),
        result_audit = joinpath(local_results, "RESULT_AUDIT.toml"),
        analysis,
        partitions = joinpath(analysis, "partitions"),
        algorithm_rows = joinpath(analysis, "algorithm_rows.parquet"),
        instance_rows = joinpath(analysis, "instance_rows.parquet"),
        summary = joinpath(analysis, "structural_summary.parquet"),
        overlap = joinpath(analysis, "identity_overlap.parquet"),
        exact_agreement = joinpath(analysis, "exact_method_agreement.parquet"),
        carrier_multiplicity = joinpath(analysis, "carrier_multiplicity.parquet"),
        figures = joinpath(analysis, "figures"),
        catalog = joinpath(analysis, "ANALYSIS_CATALOG.toml"),
        report = joinpath(analysis, "ANALYSIS_REPORT.md"),
        manifest = joinpath(analysis, "ANALYSIS_MANIFEST.toml"),
    )
end

function _exact(value::AbstractString)
    pieces = split(value, "//")
    length(pieces) == 1 && return parse(BigInt, only(pieces)) // BigInt(1)
    length(pieces) == 2 || error("invalid exact rational encoding")
    return parse(BigInt, pieces[1]) // parse(BigInt, pieces[2])
end

_exact_float(::Missing) = missing
_exact_float(value::AbstractString) = Float64(_exact(value))

function _available_value(value)
    value isa AbstractDict || return missing
    get(value, "available", false) === true || return missing
    return value["value"]
end

function _available_float(value)
    item = _available_value(value)
    ismissing(item) && return missing
    item isa AbstractString && return parse(Float64, item)
    return Float64(item)
end

function _exact_field(value)
    value isa AbstractString || return missing
    return String(value)
end

function _column_table(rows, schema)
    names = propertynames(schema)
    types = Tuple(getproperty(schema, name) for name in names)
    columns = ntuple(length(names)) do index
        name = names[index]
        type = types[index]
        return type[getproperty(row, name) for row in rows]
    end
    return NamedTuple{names}(columns)
end

function _row_table(columns)
    names = propertynames(columns)
    row_count = parquet_row_count(columns)
    return [NamedTuple{names}(Tuple(getproperty(columns, name)[index] for name in names)) for
            index in 1:row_count]
end

function _atomic_text(path, text; replace = false)
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid()).$(Threads.threadid())"
    open(temporary, "w") do io
        write(io, text)
    end
    try
        mv(temporary, path; force = replace)
    finally
        isfile(temporary) && rm(temporary; force = true)
    end
    return path
end

_atomic_toml(path, payload; replace = false) =
    _atomic_text(path, toml_text(payload); replace)

function _partition_paths(paths, stem)
    return (
        parquet = joinpath(paths.partitions, stem * ".parquet"),
        metadata = joinpath(paths.partitions, stem * ".toml"),
    )
end

function audit_ready()
    Threads.nthreads() == ANALYSIS_THREAD_COUNT || error(
        "financial panel analysis requires --threads=$ANALYSIS_THREAD_COUNT; " *
        "found $(Threads.nthreads())",
    )
    config, amendment = load_panel_config()
    paths = _paths(config)
    isfile(paths.result_audit) || error("final result audit is absent")
    audit = TOML.parsefile(paths.result_audit)
    get(audit, "passed", false) === true || error("final result audit did not pass")
    get(audit, "registered_instance_count", 0) == 180 ||
        error("final audit registered-instance count differs")
    get(audit, "registered_algorithm_terminal_rows", 0) == 1260 ||
        error("final audit algorithm-row count differs")
    get(audit, "unsuccessful_rows_retained_in_denominators", false) === true ||
        error("final audit dropped unsuccessful rows")
    amendment["amendment_id"] == "AMENDMENT_012" || error("active analysis amendment changed")
    return config, amendment, paths, audit
end

function _instance_source_burden(instance)
    return sum(instance.weights; init = zero(eltype(instance.weights)))
end

function _selected_active_ids(record, instance)
    get(record, "candidate_returned", false) === true || return String[]
    ids = String.(record["selection"]["selected_strategy_ids"])
    mandatory = Dict(string(instance.strategy_ids[index].id) => instance.mandatory[index] for
                     index in eachindex(instance.strategy_ids))
    active = sort!(String[id for id in ids if !mandatory[id]])
    return active
end

function _failure_row(
    origin_id,
    library_id,
    schedule_id,
    algorithm_id,
    instance_status,
    structural_sha,
    postdecision_sha,
)
    return (
        origin_id,
        decision_year = Int64(parse(Int, last(split(origin_id, 'O')))),
        library_id,
        schedule_id,
        algorithm_id,
        instance_status,
        structural_result_sha256 = structural_sha,
        postdecision_result_sha256 = postdecision_sha,
        exact_reference_available = false,
        source_active_strategy_count = missing,
        frontier_requirement_count = missing,
        module_requirement_count = missing,
        tagged_requirement_count = missing,
        coverage_density_exact = missing,
        coverage_density = missing,
        duplicate_coverage_count = missing,
        unique_carrier_count = missing,
        variables_before_preprocessing = missing,
        variables_after_preprocessing = missing,
        requirements_before_preprocessing = missing,
        requirements_after_preprocessing = missing,
        forced_strategy_count = missing,
        dominance_reductions = missing,
        preprocessing_fixed_point_iterations = missing,
        source_burden_exact = missing,
        source_burden = missing,
        applicable = false,
        status = instance_status,
        candidate_returned = false,
        selected_active_strategy_count = missing,
        selected_burden_exact = missing,
        selected_burden = missing,
        benchmark_burden_exact = missing,
        benchmark_burden = missing,
        absolute_burden_gap_exact = missing,
        absolute_burden_gap = missing,
        relative_burden_gap_exact = missing,
        relative_burden_gap = missing,
        optimum_attained = missing,
        wall_clock_ns = "",
        wall_clock_seconds = missing,
        termination_status = "NOT_AVAILABLE",
        primal_status = "NOT_AVAILABLE",
        dual_status = "NOT_AVAILABLE",
        solver_claimed_optimal = false,
        best_bound = missing,
        reported_gap = missing,
        mip_node_count = missing,
        dp_state_count = missing,
        frontier_checks = missing,
        closure_checks = missing,
        complete_scans = missing,
        multi_start_improvement_exact = missing,
        multi_start_improvement = missing,
        exact_mandatory_retention = missing,
        exact_tagged_coverage = missing,
        exact_frontier_preservation = missing,
        exact_closure_preservation = missing,
        exact_feasible = missing,
        selected_active_ids = "",
        selected_identity_sha256 = _sha256_text(""),
        postdecision_available = false,
        belief_losses_exact = "",
        mean_belief_loss_exact = missing,
        mean_belief_loss = missing,
        no_loss_share_exact = missing,
        no_loss_share = missing,
        identity_persistence_exact = missing,
        identity_persistence = missing,
        source_security_delisting_count = missing,
    )
end

function _algorithm_rows(stem, paths)
    structural_path = joinpath(paths.structural, stem * ".toml")
    postdecision_path = joinpath(paths.postdecision, stem * ".toml")
    structural = TOML.parsefile(structural_path)
    postdecision = TOML.parsefile(postdecision_path)
    structural_sha = sha256_file(structural_path)
    postdecision_sha = sha256_file(postdecision_path)
    origin_id, library_id, schedule_id = split(stem, "__")
    schema = String(structural["schema_version"])
    if schema != "financial-strategy-library-panel-instance-result-v1"
        status = schema == "financial-strategy-library-panel-preparation-failure-result-v1" ?
                 "PREPARATION_FAILURE" : "EXECUTION_FAILURE"
        return [_failure_row(
            origin_id,
            library_id,
            schedule_id,
            algorithm_id,
            status,
            structural_sha,
            postdecision_sha,
        ) for algorithm_id in ALGORITHM_IDS]
    end
    instance_path = joinpath(paths.instances, stem * ".toml")
    instance = open(instance_path, "r") do io
        read_journal_compression_instance(io)
    end
    source_burden = _instance_source_burden(instance)
    source_burden_exact = "$(numerator(source_burden))//$(denominator(source_burden))"
    structure = structural["structure"]
    post_algorithms = Dict(
        String(row["algorithm_id"]) => row for row in get(postdecision, "algorithms", Any[])
    )
    rows = NamedTuple[]
    for record in structural["algorithms"]
        algorithm_id = String(record["algorithm_id"])
        post = get(post_algorithms, algorithm_id, Dict{String,Any}(
            "available" => false,
        ))
        candidate = record["candidate_returned"] === true
        selection = candidate ? record["selection"] : Dict{String,Any}()
        selected_ids = _selected_active_ids(record, instance)
        selected_text = join(selected_ids, SELECTED_ID_SEPARATOR)
        selected_burden_exact = candidate ? _exact_field(selection["exact_burden"]) : missing
        benchmark_exact = _exact_field(get(record, "benchmark_burden", Dict()))
        absolute_exact = _exact_field(get(record, "absolute_burden_gap", Dict()))
        relative_exact = _exact_field(get(record, "relative_burden_gap", Dict()))
        exact_reference = structural["global_optimum_exactly_verified"] === true
        optimum_attained = exact_reference && candidate && !ismissing(absolute_exact) ?
            iszero(_exact(absolute_exact)) : missing
        losses = post["available"] === true ? String.(post["belief_losses"]) : String[]
        persistence_exact = post["available"] === true ?
            _exact_field(post["identity_persistence_to_next_origin"]) : missing
        wall_clock_ns = String(record["wall_clock_ns"])
        push!(rows, (
            origin_id,
            decision_year = Int64(parse(Int, last(split(origin_id, 'O')))),
            library_id,
            schedule_id,
            algorithm_id,
            instance_status = "SUCCESS",
            structural_result_sha256 = structural_sha,
            postdecision_result_sha256 = postdecision_sha,
            exact_reference_available = exact_reference,
            source_active_strategy_count = Int64(structure["active_strategy_count"]),
            frontier_requirement_count = Int64(structure["frontier_requirement_count"]),
            module_requirement_count = Int64(structure["module_requirement_count"]),
            tagged_requirement_count = Int64(structure["tagged_requirement_count"]),
            coverage_density_exact = String(structure["coverage_density"]),
            coverage_density = _exact_float(String(structure["coverage_density"])),
            duplicate_coverage_count = Int64(structure["duplicate_coverage_count"]),
            unique_carrier_count = Int64(structure["unique_carrier_count"]),
            variables_before_preprocessing = Int64(structure["variables_before_preprocessing"]),
            variables_after_preprocessing = Int64(structure["variables_after_preprocessing"]),
            requirements_before_preprocessing = Int64(structure["requirements_before_preprocessing"]),
            requirements_after_preprocessing = Int64(structure["requirements_after_preprocessing"]),
            forced_strategy_count = Int64(structure["forced_strategy_count"]),
            dominance_reductions = Int64(structure["dominance_reductions"]),
            preprocessing_fixed_point_iterations = Int64(structure["preprocessing_fixed_point_iterations"]),
            source_burden_exact,
            source_burden = Float64(source_burden),
            applicable = record["applicable"] === true,
            status = String(record["status"]),
            candidate_returned = candidate,
            selected_active_strategy_count = candidate ?
                Int64(selection["selected_active_strategy_count"]) : missing,
            selected_burden_exact,
            selected_burden = _exact_float(selected_burden_exact),
            benchmark_burden_exact = benchmark_exact,
            benchmark_burden = _exact_float(benchmark_exact),
            absolute_burden_gap_exact = absolute_exact,
            absolute_burden_gap = _exact_float(absolute_exact),
            relative_burden_gap_exact = relative_exact,
            relative_burden_gap = _exact_float(relative_exact),
            optimum_attained,
            wall_clock_ns,
            wall_clock_seconds = isempty(wall_clock_ns) ? missing : parse(Float64, wall_clock_ns) / 1e9,
            termination_status = String(record["termination_status"]),
            primal_status = String(record["primal_status"]),
            dual_status = String(record["dual_status"]),
            solver_claimed_optimal = record["solver_claimed_optimal"] === true,
            best_bound = _available_float(record["best_bound"]),
            reported_gap = _available_float(record["reported_gap"]),
            mip_node_count = _available_float(record["mip_node_count"]),
            dp_state_count = _available_float(record["dp_state_count"]),
            frontier_checks = _available_float(record["frontier_checks"]),
            closure_checks = _available_float(record["closure_checks"]),
            complete_scans = _available_float(record["complete_scans"]),
            multi_start_improvement_exact = _exact_field(get(record, "multi_start_improvement", Dict())),
            multi_start_improvement = _exact_float(
                _exact_field(get(record, "multi_start_improvement", Dict())),
            ),
            exact_mandatory_retention = candidate ?
                Bool(selection["exact_mandatory_retention"]) : missing,
            exact_tagged_coverage = candidate ? Bool(selection["exact_tagged_coverage"]) : missing,
            exact_frontier_preservation = candidate ?
                Bool(selection["exact_frontier_preservation"]) : missing,
            exact_closure_preservation = candidate ?
                Bool(selection["exact_closure_preservation"]) : missing,
            exact_feasible = candidate ? Bool(selection["exact_feasible"]) : missing,
            selected_active_ids = selected_text,
            selected_identity_sha256 = _sha256_text(selected_text),
            postdecision_available = post["available"] === true,
            belief_losses_exact = join(losses, ';'),
            mean_belief_loss_exact = post["available"] === true ?
                String(post["mean_belief_loss"]) : missing,
            mean_belief_loss = post["available"] === true ?
                _exact_float(String(post["mean_belief_loss"])) : missing,
            no_loss_share_exact = post["available"] === true ?
                String(post["no_loss_share"]) : missing,
            no_loss_share = post["available"] === true ?
                _exact_float(String(post["no_loss_share"])) : missing,
            identity_persistence_exact = persistence_exact,
            identity_persistence = _exact_float(persistence_exact),
            source_security_delisting_count = post["available"] === true ?
                Int64(postdecision["source_security_count_with_delisting_flag"]) : missing,
        ))
    end
    return rows
end

function _partition_valid(partition, expected_result_audit_sha256, expected_lock)
    isfile(partition.metadata) || return false
    isfile(partition.parquet) || error("terminal analysis partition metadata has no Parquet file")
    metadata = TOML.parsefile(partition.metadata)
    metadata["schema_version"] == "financial-panel-analysis-partition-v1" ||
        error("unexpected analysis partition schema")
    metadata["result_audit_sha256"] == expected_result_audit_sha256 ||
        error("analysis partition is bound to a different result audit")
    metadata["execution_lock_aggregate_sha256"] == expected_lock ||
        error("analysis partition is bound to a different execution lock")
    sha256_file(partition.parquet) == metadata["parquet_sha256"] ||
        error("analysis partition hash differs")
    validate_parquet(
        partition.parquet;
        expected_columns = propertynames(ALGORITHM_SCHEMA),
        expected_rows = 7,
    )
    return true
end

function _write_partition(stem, paths, result_audit_sha256, execution_lock)
    partition = _partition_paths(paths, stem)
    if isfile(partition.parquet) && !isfile(partition.metadata)
        rm(partition.parquet; force = true)
    end
    _partition_valid(partition, result_audit_sha256, execution_lock) && return :reused
    rows = _algorithm_rows(stem, paths)
    length(rows) == 7 || error("analysis partition does not contain seven algorithm rows")
    columns = _column_table(rows, ALGORITHM_SCHEMA)
    atomic_write_parquet(partition.parquet, columns; replace = true)
    metadata = Dict{String,Any}(
        "schema_version" => "financial-panel-analysis-partition-v1",
        "stem" => stem,
        "execution_lock_aggregate_sha256" => execution_lock,
        "result_audit_sha256" => result_audit_sha256,
        "structural_result_sha256" => only(unique(columns.structural_result_sha256)),
        "postdecision_result_sha256" => only(unique(columns.postdecision_result_sha256)),
        "algorithm_row_count" => 7,
        "parquet_compression" => "SNAPPY",
        "parquet_sha256" => sha256_file(partition.parquet),
        "raw_licensed_rows_included" => false,
    )
    _atomic_toml(partition.metadata, metadata)
    _partition_valid(partition, result_audit_sha256, execution_lock) ||
        error("new analysis partition did not validate")
    return :created
end

function _progress(io, completed, total, reused)
    width = 36
    filled = total == 0 ? width : fld(completed * width, total)
    bar = repeat("█", filled) * repeat("░", width - filled)
    println(
        io,
        "[$(_utc_now())] panel-analysis [$bar] $completed/$total reused=$reused",
    )
    flush(io)
end

function _write_partitions(stems, paths, result_audit_sha256, execution_lock; progress_io = stderr)
    completed = Threads.Atomic{Int}(0)
    reused = Threads.Atomic{Int}(0)
    progress_lock = ReentrantLock()
    errors = Vector{Union{Nothing,String}}(undef, length(stems))
    fill!(errors, nothing)
    _progress(progress_io, 0, length(stems), 0)
    Threads.@threads :static for index in eachindex(stems)
        try
            status = _write_partition(
                stems[index],
                paths,
                result_audit_sha256,
                execution_lock,
            )
            status == :reused && Threads.atomic_add!(reused, 1)
        catch exception
            errors[index] = sprint(showerror, exception)
        end
        lock(progress_lock) do
            count = Threads.atomic_add!(completed, 1) + 1
            _progress(progress_io, count, length(stems), reused[])
        end
    end
    failures = findall(!isnothing, errors)
    isempty(failures) || error(join(("$(stems[index]): $(errors[index])" for index in failures), "; "))
    return reused[]
end

function _combine_partitions(stems, paths)
    rows = NamedTuple[]
    for stem in stems
        append!(rows, _row_table(parquet_columns(_partition_paths(paths, stem).parquet)))
    end
    length(rows) == 1260 || error("combined analysis does not contain 1260 algorithm rows")
    sort!(rows; by = row -> (
        row.origin_id,
        row.library_id,
        row.schedule_id,
        findfirst(==(row.algorithm_id), ALGORITHM_IDS),
    ))
    atomic_write_parquet(paths.algorithm_rows, _column_table(rows, ALGORITHM_SCHEMA); replace = true)
    return rows
end

function _median(values)
    isempty(values) && return missing
    ordered = sort!(Float64.(values))
    n = length(ordered)
    isodd(n) && return ordered[(n + 1) ÷ 2]
    return (ordered[n ÷ 2] + ordered[n ÷ 2 + 1]) / 2
end

function _nearest_quantile(values, probability)
    isempty(values) && return missing
    ordered = sort!(Float64.(values))
    return ordered[clamp(ceil(Int, probability * length(ordered)), 1, length(ordered))]
end

_mean(values) = isempty(values) ? missing : sum(values) / length(values)
_maximum(values) = isempty(values) ? missing : maximum(values)

function _summary_rows(rows)
    result = NamedTuple[]
    libraries = sort!(unique(row.library_id for row in rows))
    schedules = sort!(unique(row.schedule_id for row in rows))
    for library_id in libraries, schedule_id in schedules, algorithm_id in ALGORITHM_IDS
        group = [row for row in rows if row.library_id == library_id &&
                 row.schedule_id == schedule_id && row.algorithm_id == algorithm_id]
        length(group) == 20 || error("analysis summary group does not contain 20 origins")
        exact_reference = [row for row in group if row.exact_reference_available]
        attained = [row for row in exact_reference if row.optimum_attained === true]
        absolute = Float64[row.absolute_burden_gap for row in group if !ismissing(row.absolute_burden_gap)]
        relative = Float64[row.relative_burden_gap for row in group if !ismissing(row.relative_burden_gap)]
        runtime = Float64[row.wall_clock_seconds for row in group if !ismissing(row.wall_clock_seconds)]
        nodes = Float64[row.mip_node_count for row in group if !ismissing(row.mip_node_count)]
        states = Float64[row.dp_state_count for row in group if !ismissing(row.dp_state_count)]
        evaluations = Float64[
            row.frontier_checks + row.closure_checks for row in group if
            !ismissing(row.frontier_checks) && !ismissing(row.closure_checks)
        ]
        improvements = Float64[
            row.multi_start_improvement for row in group if
            !ismissing(row.multi_start_improvement)
        ]
        losses = Float64[row.mean_belief_loss for row in group if !ismissing(row.mean_belief_loss)]
        no_loss = Float64[row.no_loss_share for row in group if !ismissing(row.no_loss_share)]
        push!(result, (
            library_id,
            schedule_id,
            algorithm_id,
            registered_instance_count = Int64(length(group)),
            successful_instance_count = Int64(count(row -> row.instance_status == "SUCCESS", group)),
            failure_instance_count = Int64(count(row -> row.instance_status != "SUCCESS", group)),
            applicable_count = Int64(count(row -> row.applicable, group)),
            candidate_count = Int64(count(row -> row.candidate_returned, group)),
            exactly_feasible_count = Int64(count(row -> row.exact_feasible === true, group)),
            exact_reference_count = Int64(length(exact_reference)),
            optimum_attainment_count = Int64(length(attained)),
            optimum_attainment_frequency = isempty(exact_reference) ? missing :
                length(attained) / length(exact_reference),
            absolute_gap_count = Int64(length(absolute)),
            absolute_gap_mean = _mean(absolute),
            absolute_gap_median = _median(absolute),
            absolute_gap_q25 = _nearest_quantile(absolute, 0.25),
            absolute_gap_q75 = _nearest_quantile(absolute, 0.75),
            absolute_gap_p90 = _nearest_quantile(absolute, 0.90),
            absolute_gap_max = _maximum(absolute),
            relative_gap_count = Int64(length(relative)),
            relative_gap_mean = _mean(relative),
            relative_gap_median = _median(relative),
            relative_gap_q25 = _nearest_quantile(relative, 0.25),
            relative_gap_q75 = _nearest_quantile(relative, 0.75),
            relative_gap_p90 = _nearest_quantile(relative, 0.90),
            relative_gap_max = _maximum(relative),
            runtime_count = Int64(length(runtime)),
            runtime_mean_seconds = _mean(runtime),
            runtime_median_seconds = _median(runtime),
            runtime_q25_seconds = _nearest_quantile(runtime, 0.25),
            runtime_q75_seconds = _nearest_quantile(runtime, 0.75),
            runtime_p90_seconds = _nearest_quantile(runtime, 0.90),
            runtime_max_seconds = _maximum(runtime),
            mip_node_count = Int64(length(nodes)),
            mip_nodes_median = _median(nodes),
            dp_state_count = Int64(length(states)),
            dp_states_median = _median(states),
            exact_evaluation_count = Int64(length(evaluations)),
            exact_evaluations_median = _median(evaluations),
            multistart_improvement_count = Int64(length(improvements)),
            multistart_improvement_mean = _mean(improvements),
            postdecision_available_count = Int64(length(losses)),
            mean_belief_loss_mean = _mean(losses),
            no_loss_share_mean = _mean(no_loss),
        ))
    end
    return result
end

function _registered_groups(rows)
    groups = Dict{Tuple{String,String,String},Vector{NamedTuple}}()
    for row in rows
        key = (row.origin_id, row.library_id, row.schedule_id)
        push!(get!(groups, key, NamedTuple[]), row)
    end
    expected = Set(registered_job_keys())
    Set(keys(groups)) == expected || error("analysis instance groups differ from the registry")
    all(==(length(ALGORITHM_IDS)), length.(values(groups))) ||
        error("an analysis instance group does not contain every registered algorithm")
    return groups
end

function _single_nonmissing(group, name)
    values = unique(getproperty(row, name) for row in group if !ismissing(getproperty(row, name)))
    length(values) <= 1 || error("instance rows disagree on $name")
    return isempty(values) ? missing : only(values)
end

function _reduction_fraction(before, after)
    ismissing(before) || ismissing(after) || iszero(before) ? missing :
        (before - after) / before
end

function _instance_rows(rows)
    groups = _registered_groups(rows)
    result = NamedTuple[]
    for key in sort!(collect(keys(groups)))
        group = groups[key]
        representative = first(group)
        statuses = unique(row.instance_status for row in group)
        length(statuses) == 1 || error("algorithm rows disagree on instance status")
        exact_flags = unique(row.exact_reference_available for row in group)
        length(exact_flags) == 1 || error("algorithm rows disagree on exact-reference status")
        variables_before = _single_nonmissing(group, :variables_before_preprocessing)
        variables_after = _single_nonmissing(group, :variables_after_preprocessing)
        requirements_before = _single_nonmissing(group, :requirements_before_preprocessing)
        requirements_after = _single_nonmissing(group, :requirements_after_preprocessing)
        source_exact = _single_nonmissing(group, :source_burden_exact)
        source = _single_nonmissing(group, :source_burden)
        benchmark_exact = _single_nonmissing(group, :benchmark_burden_exact)
        benchmark = _single_nonmissing(group, :benchmark_burden)
        saving = ismissing(source) || ismissing(benchmark) || iszero(source) ? missing :
            (source - benchmark) / source
        push!(result, (
            origin_id = representative.origin_id,
            decision_year = representative.decision_year,
            library_id = representative.library_id,
            schedule_id = representative.schedule_id,
            instance_status = only(statuses),
            exact_reference_available = only(exact_flags),
            source_active_strategy_count = _single_nonmissing(group, :source_active_strategy_count),
            frontier_requirement_count = _single_nonmissing(group, :frontier_requirement_count),
            module_requirement_count = _single_nonmissing(group, :module_requirement_count),
            tagged_requirement_count = _single_nonmissing(group, :tagged_requirement_count),
            coverage_density_exact = _single_nonmissing(group, :coverage_density_exact),
            coverage_density = _single_nonmissing(group, :coverage_density),
            duplicate_coverage_count = _single_nonmissing(group, :duplicate_coverage_count),
            unique_carrier_count = _single_nonmissing(group, :unique_carrier_count),
            forced_strategy_count = _single_nonmissing(group, :forced_strategy_count),
            dominance_reductions = _single_nonmissing(group, :dominance_reductions),
            variables_before_preprocessing = variables_before,
            variables_after_preprocessing = variables_after,
            variable_reduction_fraction = _reduction_fraction(variables_before, variables_after),
            requirements_before_preprocessing = requirements_before,
            requirements_after_preprocessing = requirements_after,
            requirement_reduction_fraction =
                _reduction_fraction(requirements_before, requirements_after),
            preprocessing_empty_residual =
                ismissing(variables_after) || ismissing(requirements_after) ? missing :
                iszero(variables_after) && iszero(requirements_after),
            source_burden_exact = source_exact,
            source_burden = source,
            benchmark_burden_exact = benchmark_exact,
            benchmark_burden = benchmark,
            certified_burden_saving_fraction = saving,
        ))
    end
    length(result) == 180 || error("instance analysis does not contain 180 registered rows")
    return result
end

function _algorithm_record(group, algorithm_id)
    matches = filter(row -> row.algorithm_id == algorithm_id, group)
    length(matches) == 1 || error("algorithm row is absent or duplicated: $algorithm_id")
    return only(matches)
end

function _agreement_if_available(left, right, field)
    left.candidate_returned && right.candidate_returned || return missing
    left_value = getproperty(left, field)
    right_value = getproperty(right, field)
    ismissing(left_value) || ismissing(right_value) ? missing : left_value == right_value
end

function _agreement_rows(rows)
    groups = _registered_groups(rows)
    result = NamedTuple[]
    for key in sort!(collect(keys(groups)))
        group = groups[key]
        representative = first(group)
        dp = _algorithm_record(group, "requirement_mask_dp")
        enumeration = _algorithm_record(group, "complete_enumeration")
        mip = _algorithm_record(group, "jump_highs_tagged_cover")
        exact_row = dp.candidate_returned ? dp :
                    enumeration.candidate_returned ? enumeration : nothing
        mip_exact_objective_agreement = isnothing(exact_row) ? missing :
            _agreement_if_available(mip, exact_row, :selected_burden_exact)
        mip_exact_optimizer_identity_agreement = isnothing(exact_row) ? missing :
            _agreement_if_available(mip, exact_row, :selected_identity_sha256)
        push!(result, (
            origin_id = representative.origin_id,
            decision_year = representative.decision_year,
            library_id = representative.library_id,
            schedule_id = representative.schedule_id,
            instance_status = representative.instance_status,
            exact_reference_available = representative.exact_reference_available,
            dp_candidate_returned = dp.candidate_returned,
            enumeration_candidate_returned = enumeration.candidate_returned,
            mip_candidate_returned = mip.candidate_returned,
            dp_burden_exact = dp.selected_burden_exact,
            enumeration_burden_exact = enumeration.selected_burden_exact,
            mip_burden_exact = mip.selected_burden_exact,
            dp_enumeration_objective_agreement =
                _agreement_if_available(dp, enumeration, :selected_burden_exact),
            mip_exact_objective_agreement,
            mip_solver_claimed_optimal = mip.solver_claimed_optimal,
            mip_solver_status_used_as_exact_proof = false,
            dp_enumeration_optimizer_identity_agreement =
                _agreement_if_available(dp, enumeration, :selected_identity_sha256),
            mip_exact_optimizer_identity_agreement,
        ))
    end
    length(result) == 180 || error("exact-method agreement does not contain 180 rows")
    return result
end

function _carrier_rows(stems, paths)
    rows = NamedTuple[]
    for stem in stems
        instance_path = joinpath(paths.instances, stem * ".toml")
        isfile(instance_path) || continue
        instance = open(instance_path, "r") do io
            read_journal_compression_instance(io)
        end
        origin_id, library_id, schedule_id = split(stem, "__")
        decision_year = Int64(parse(Int, last(split(origin_id, 'O'))))
        for requirement_index in axes(instance.coverage, 1)
            carrier_count = Int64(count(instance.coverage[requirement_index, :]))
            carrier_count > 0 || error("a serialized instance contains a carrierless requirement")
            requirement = instance.requirements[requirement_index]
            requirement_kind = requirement isa FrontierRequirement ? "frontier" :
                               requirement isa ModuleRequirement ? "module" :
                               error("unknown tagged-requirement type")
            push!(rows, (
                origin_id,
                decision_year,
                library_id,
                schedule_id,
                requirement_index = Int64(requirement_index),
                requirement_kind,
                carrier_count,
                unique_carrier = carrier_count == 1,
            ))
        end
    end
    sort!(rows; by = row -> (
        row.origin_id,
        row.library_id,
        row.schedule_id,
        row.requirement_index,
    ))
    return rows
end

function _identity_set(row)
    row.candidate_returned || return nothing
    isempty(row.selected_active_ids) && return Set{String}()
    return Set(String.(split(row.selected_active_ids, SELECTED_ID_SEPARATOR)))
end

function _overlap_row(left, right, comparison_type, schedule_id, algorithm_id)
    left_set = _identity_set(left)
    right_set = _identity_set(right)
    available = !isnothing(left_set) && !isnothing(right_set)
    intersection_count = available ? Int64(length(intersect(left_set, right_set))) : missing
    union_count = available ? Int64(length(union(left_set, right_set))) : missing
    jaccard = if !available
        missing
    elseif union_count == 0
        1.0
    else
        intersection_count / union_count
    end
    return (
        origin_id = left.origin_id,
        decision_year = left.decision_year,
        library_id = left.library_id,
        schedule_id,
        algorithm_id,
        comparison_type,
        left_id = comparison_type == "algorithm" ? left.algorithm_id : left.schedule_id,
        right_id = comparison_type == "algorithm" ? right.algorithm_id : right.schedule_id,
        available,
        intersection_count,
        union_count,
        jaccard,
    )
end

function _overlap_rows(rows)
    result = NamedTuple[]
    origins = sort!(unique(row.origin_id for row in rows))
    libraries = sort!(unique(row.library_id for row in rows))
    schedules = sort!(unique(row.schedule_id for row in rows))
    for origin_id in origins, library_id in libraries, schedule_id in schedules
        group = Dict(row.algorithm_id => row for row in rows if row.origin_id == origin_id &&
                     row.library_id == library_id && row.schedule_id == schedule_id)
        for left_index in 1:(length(ALGORITHM_IDS) - 1), right_index in (left_index + 1):length(ALGORITHM_IDS)
            push!(result, _overlap_row(
                group[ALGORITHM_IDS[left_index]],
                group[ALGORITHM_IDS[right_index]],
                "algorithm",
                schedule_id,
                "",
            ))
        end
    end
    for origin_id in origins, library_id in libraries, algorithm_id in ALGORITHM_IDS
        group = Dict(row.schedule_id => row for row in rows if row.origin_id == origin_id &&
                     row.library_id == library_id && row.algorithm_id == algorithm_id)
        for left_index in 1:(length(schedules) - 1), right_index in (left_index + 1):length(schedules)
            push!(result, _overlap_row(
                group[schedules[left_index]],
                group[schedules[right_index]],
                "schedule",
                "",
                algorithm_id,
            ))
        end
    end
    return result
end

_svg_escape(value) = replace(
    string(value),
    '&' => "&amp;",
    '<' => "&lt;",
    '>' => "&gt;",
    '"' => "&quot;",
)

function _svg_text(io, x, y, value; size = 12, anchor = "start", weight = "normal")
    println(
        io,
        "<text x=\"$x\" y=\"$y\" font-family=\"Helvetica,Arial,sans-serif\" " *
        "font-size=\"$size\" text-anchor=\"$anchor\" font-weight=\"$weight\" " *
        "fill=\"#172B4D\">$(_svg_escape(value))</text>",
    )
end

function _svg_marker(io, x, y, marker; color = "#175CD3", open = false)
    fill = open ? "#FFFFFF" : color
    marker == 1 && return println(io,
        "<circle cx=\"$x\" cy=\"$y\" r=\"4\" fill=\"$fill\" stroke=\"$color\" stroke-width=\"1.5\"/>")
    marker == 2 && return println(io,
        "<rect x=\"$(x - 4)\" y=\"$(y - 4)\" width=\"8\" height=\"8\" fill=\"$fill\" stroke=\"$color\" stroke-width=\"1.5\"/>")
    return println(io,
        "<path d=\"M $x $(y - 5) L $(x + 5) $(y + 4) L $(x - 5) $(y + 4) Z\" fill=\"$fill\" stroke=\"$color\" stroke-width=\"1.5\"/>")
end

function _write_svg(path, title, subtitle, draw; width = 1280, height = 760)
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do io
        println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\" role=\"img\" aria-labelledby=\"title desc\">")
        println(io, "<title id=\"title\">$(_svg_escape(title))</title>")
        println(io, "<desc id=\"desc\">$(_svg_escape(subtitle))</desc>")
        println(io, "<rect width=\"100%\" height=\"100%\" fill=\"#FFFFFF\"/>")
        _svg_text(io, 42, 38, title; size = 22, weight = "bold")
        _svg_text(io, 42, 62, subtitle; size = 11)
        draw(io)
        println(io, "</svg>")
    end
    try
        mv(temporary, path; force = true)
    finally
        isfile(temporary) && rm(temporary; force = true)
    end
    return path
end

_write_svg(draw::Function, path, title, subtitle; kwargs...) =
    _write_svg(path, title, subtitle, draw; kwargs...)

function _plot_origin_compression(instances, path)
    libraries = sort!(unique(row.library_id for row in instances))
    schedules = sort!(unique(row.schedule_id for row in instances))
    colors = ("#175CD3", "#B54708", "#027A48")
    _write_svg(
        path,
        "Origin-by-origin certified compression",
        "Best certified burden saving by library and schedule; × marks retain registered failures.",
    ) do io
        left, width = 150.0, 1050.0
        years = sort!(unique(row.decision_year for row in instances))
        xmin, xmax = extrema(years)
        xmap(year) = left + width * (year - xmin) / max(xmax - xmin, 1)
        for (panel, library) in enumerate(libraries)
            top = 90.0 + (panel - 1) * 205
            height = 145.0
            group = filter(row -> row.library_id == library, instances)
            finite = Float64[row.certified_burden_saving_fraction for row in group if
                             !ismissing(row.certified_burden_saving_fraction)]
            ymax = isempty(finite) ? 1.0 : max(maximum(finite), 0.01)
            println(io, "<line x1=\"$left\" y1=\"$top\" x2=\"$left\" y2=\"$(top + height)\" stroke=\"#344054\"/>")
            println(io, "<line x1=\"$left\" y1=\"$(top + height)\" x2=\"$(left + width)\" y2=\"$(top + height)\" stroke=\"#344054\"/>")
            _svg_text(io, 42, top + 18, library; size = 12, weight = "bold")
            _svg_text(io, 142, top + 5, @sprintf("%.3g", ymax); size = 9, anchor = "end")
            for row in group
                schedule_index = findfirst(==(row.schedule_id), schedules)
                x = xmap(row.decision_year) + 4 * (schedule_index - 2)
                if ismissing(row.certified_burden_saving_fraction)
                    y = top + height
                    println(io, "<path d=\"M $(x-4) $(y-4) L $(x+4) $(y+4) M $(x+4) $(y-4) L $(x-4) $(y+4)\" stroke=\"#667085\" stroke-width=\"1.5\"/>")
                else
                    y = top + height * (1 - row.certified_burden_saving_fraction / ymax)
                    _svg_marker(io, x, y, schedule_index; color = colors[schedule_index])
                end
            end
            for year in years[1:4:end]
                _svg_text(io, xmap(year), top + height + 17, year; size = 8, anchor = "middle")
            end
        end
        for (index, schedule) in enumerate(schedules)
            x = 200 + (index - 1) * 330
            _svg_marker(io, x, 730, index; color = colors[index])
            _svg_text(io, x + 10, 734, schedule; size = 10)
        end
    end
end

function _cactus_points(group, target)
    times = sort!(Float64[row.wall_clock_seconds for row in group if
                          !ismissing(row.wall_clock_seconds) && target(row)])
    denominator = 180
    return [(time, index / denominator) for (index, time) in enumerate(times)]
end

function _plot_cactus(rows, path)
    algorithms = ALGORITHM_IDS
    colors = ("#175CD3", "#B54708", "#027A48", "#7F56D9", "#C11574", "#026AA2", "#475467")
    panels = (
        ("exact feasibility", row -> row.exact_feasible === true, algorithms),
        ("exact optimum attained", row -> row.optimum_attained === true, algorithms),
        ("exact-method completion", row -> row.candidate_returned &&
            row.algorithm_id in ("requirement_mask_dp", "complete_enumeration"),
            ["requirement_mask_dp", "complete_enumeration"]),
    )
    finite_times = Float64[row.wall_clock_seconds for row in rows if !ismissing(row.wall_clock_seconds)]
    xmax = isempty(finite_times) ? 1.0 : max(maximum(finite_times), 1e-6)
    _write_svg(
        path,
        "Registered completion cactus plots",
        "Fractions use 180 registered instances per algorithm; failures and inapplicability remain unsolved.",
    ) do io
        for (panel_index, (label, target, panel_algorithms)) in enumerate(panels)
            left = 70.0 + (panel_index - 1) * 405
            top, width, height = 120.0, 350.0, 470.0
            println(io, "<line x1=\"$left\" y1=\"$top\" x2=\"$left\" y2=\"$(top+height)\" stroke=\"#344054\"/>")
            println(io, "<line x1=\"$left\" y1=\"$(top+height)\" x2=\"$(left+width)\" y2=\"$(top+height)\" stroke=\"#344054\"/>")
            _svg_text(io, left + width / 2, 100, label; size = 13, anchor = "middle", weight = "bold")
            for algorithm in panel_algorithms
                group = filter(row -> row.algorithm_id == algorithm, rows)
                points = _cactus_points(group, target)
                isempty(points) && continue
                index = findfirst(==(algorithm), algorithms)
                coordinates = join((@sprintf("%.2f,%.2f", left + width * time / xmax,
                    top + height * (1 - fraction)) for (time, fraction) in points), " ")
                dash = isodd(index) ? "" : " stroke-dasharray=\"7 4\""
                println(io, "<polyline points=\"$coordinates\" fill=\"none\" stroke=\"$(colors[index])\" stroke-width=\"1.8\"$dash/>")
                time, fraction = last(points)
                _svg_marker(io, left + width * time / xmax, top + height * (1 - fraction),
                    mod1(index, 3); color = colors[index], open = iseven(index))
            end
            _svg_text(io, left + width / 2, top + height + 28, "wall-clock seconds (linear, full range)"; size = 9, anchor = "middle")
            _svg_text(io, left - 8, top + 5, "1"; size = 9, anchor = "end")
            _svg_text(io, left - 8, top + height + 4, "0"; size = 9, anchor = "end")
        end
        _svg_text(io, 52, 650, "Solid/open and dashed markers distinguish algorithms in addition to color."; size = 10)
        for (index, algorithm) in enumerate(algorithms)
            x = 70 + 390 * ((index - 1) % 3)
            y = 680 + 22 * div(index - 1, 3)
            _svg_marker(io, x, y - 4, mod1(index, 3); color = colors[index], open = iseven(index))
            _svg_text(io, x + 10, y, algorithm; size = 9)
        end
    end
end

function _plot_carriers(instances, carriers, path)
    carrier_groups = Dict{Tuple{String,String,String},Vector{Int64}}()
    for row in carriers
        key = (row.origin_id, row.library_id, row.schedule_id)
        push!(get!(carrier_groups, key, Int64[]), row.carrier_count)
    end
    points = NamedTuple[]
    for row in instances
        key = (row.origin_id, row.library_id, row.schedule_id)
        haskey(carrier_groups, key) || continue
        ismissing(row.certified_burden_saving_fraction) && continue
        push!(points, (row, median_carriers = _median(carrier_groups[key])))
    end
    xmax = isempty(points) ? 1.0 : max(maximum(point.median_carriers for point in points), 1.0)
    ymax = isempty(points) ? 1.0 : max(maximum(point.row.certified_burden_saving_fraction for point in points), 0.01)
    libraries = sort!(unique(row.library_id for row in instances))
    colors = ("#175CD3", "#B54708", "#027A48")
    _write_svg(
        path,
        "Carrier multiplicity and certified compression",
        "Every valid origin-library-schedule instance is shown; medians summarize its tagged requirements.",
    ) do io
        left, top, width, height = 110.0, 110.0, 1080.0, 520.0
        println(io, "<rect x=\"$left\" y=\"$top\" width=\"$width\" height=\"$height\" fill=\"none\" stroke=\"#344054\"/>")
        for point in points
            library_index = findfirst(==(point.row.library_id), libraries)
            x = left + width * point.median_carriers / xmax
            y = top + height * (1 - point.row.certified_burden_saving_fraction / ymax)
            _svg_marker(io, x, y, library_index; color = colors[library_index], open = iseven(point.row.decision_year))
        end
        _svg_text(io, left + width / 2, 670, "median number of source carriers per tagged requirement"; size = 11, anchor = "middle")
        _svg_text(io, 20, 95, @sprintf("saving range: 0 to %.3g", ymax); size = 10)
        for (index, library) in enumerate(libraries)
            x = 180 + (index - 1) * 350
            _svg_marker(io, x, 715, index; color = colors[index])
            _svg_text(io, x + 10, 719, library; size = 9)
        end
    end
end

function _plot_schedule_overlap(overlaps, path)
    rows = filter(row -> row.comparison_type == "schedule" && row.available, overlaps)
    algorithms = ALGORITHM_IDS
    pairs = sort!(unique((row.left_id, row.right_id) for row in rows))
    colors = ("#175CD3", "#B54708", "#027A48")
    _write_svg(
        path,
        "Selected-identity overlap across burden schedules",
        "Jaccard comparisons remain within the same origin, library, and algorithm; unavailable pairs are omitted, not zeroed.",
    ) do io
        left, top, width, height = 220.0, 105.0, 960.0, 520.0
        println(io, "<rect x=\"$left\" y=\"$top\" width=\"$width\" height=\"$height\" fill=\"none\" stroke=\"#344054\"/>")
        for (algorithm_index, algorithm) in enumerate(algorithms)
            xbase = left + width * (algorithm_index - 0.5) / length(algorithms)
            group = filter(row -> row.algorithm_id == algorithm, rows)
            for row in group
                pair_index = findfirst(==((row.left_id, row.right_id)), pairs)
                x = xbase + 7 * (pair_index - 2)
                y = top + height * (1 - row.jaccard)
                _svg_marker(io, x, y, pair_index; color = colors[pair_index], open = iseven(row.decision_year))
            end
            _svg_text(io, xbase, top + height + 18, replace(algorithm, '_' => ' '); size = 8, anchor = "middle")
        end
        for (index, pair) in enumerate(pairs)
            _svg_marker(io, 245, 675 + 20 * index, index; color = colors[index])
            _svg_text(io, 257, 679 + 20 * index, "$(pair[1]) vs $(pair[2])"; size = 9)
        end
    end
end

function _plot_postdecision(rows, path)
    libraries = sort!(unique(row.library_id for row in rows))
    algorithms = ALGORITHM_IDS
    colors = ("#175CD3", "#B54708", "#027A48", "#7F56D9", "#C11574", "#026AA2", "#475467")
    _write_svg(
        path,
        "Postdecision operating-opportunity diagnostics",
        "Retrospective mean belief loss after certified selection; panels keep library constructions separate.",
    ) do io
        for (panel, library) in enumerate(libraries)
            left = 70.0 + (panel - 1) * 405
            top, width, height = 120.0, 350.0, 480.0
            group = filter(row -> row.library_id == library && row.postdecision_available, rows)
            finite = Float64[row.mean_belief_loss for row in group if !ismissing(row.mean_belief_loss)]
            ymax = isempty(finite) ? 1.0 : max(maximum(finite), 1e-12)
            years = sort!(unique(row.decision_year for row in rows))
            xmin, xmax = extrema(years)
            println(io, "<rect x=\"$left\" y=\"$top\" width=\"$width\" height=\"$height\" fill=\"none\" stroke=\"#344054\"/>")
            _svg_text(io, left + width / 2, 100, library; size = 12, anchor = "middle", weight = "bold")
            for row in group
                ismissing(row.mean_belief_loss) && continue
                algorithm_index = findfirst(==(row.algorithm_id), algorithms)
                x = left + width * (row.decision_year - xmin) / max(xmax - xmin, 1)
                y = top + height * (1 - row.mean_belief_loss / ymax)
                _svg_marker(io, x, y, mod1(algorithm_index, 3); color = colors[algorithm_index], open = iseven(algorithm_index))
            end
            _svg_text(io, left + width / 2, top + height + 28, "decision origin"; size = 9, anchor = "middle")
            _svg_text(io, left - 5, top + 4, @sprintf("%.3g", ymax); size = 8, anchor = "end")
        end
        _svg_text(io, 52, 655, "Every available algorithm-schedule row is shown; absent diagnostics remain in the linked Parquet denominator."; size = 10)
    end
end

function _analysis_figures(rows, instances, overlaps, carriers, paths)
    mkpath(paths.figures)
    outputs = [
        _plot_origin_compression(instances, joinpath(paths.figures, "origin_compression.svg")),
        _plot_cactus(rows, joinpath(paths.figures, "completion_cactus.svg")),
        _plot_carriers(instances, carriers, joinpath(paths.figures, "carrier_multiplicity_compression.svg")),
        _plot_schedule_overlap(overlaps, joinpath(paths.figures, "schedule_identity_overlap.svg")),
        _plot_postdecision(rows, joinpath(paths.figures, "postdecision_diagnostics.svg")),
    ]
    return outputs
end

function _analysis_catalog(paths)
    return Dict{String,Any}(
        "schema_version" => "financial-panel-analysis-catalog-v1",
        "tables" => [
            Dict("registered_item" => "origin-eligible universe and source-library structure", "source" => basename(paths.instance_rows)),
            Dict("registered_item" => "capability ownership and carrier multiplicity", "source" => basename(paths.carrier_multiplicity)),
            Dict("registered_item" => "burden calibration and source burden", "source" => basename(paths.instance_rows)),
            Dict("registered_item" => "exact-method agreement and solver evidence", "source" => basename(paths.exact_agreement)),
            Dict("registered_item" => "algorithm burden gap", "source" => basename(paths.summary)),
            Dict("registered_item" => "preprocessing reduction", "source" => basename(paths.instance_rows)),
            Dict("registered_item" => "failure and applicability census", "source" => basename(paths.summary)),
        ],
        "figures" => [
            Dict("registered_item" => "origin-by-origin compression", "file" => "figures/origin_compression.svg", "source" => basename(paths.instance_rows)),
            Dict("registered_item" => "feasibility, quality, and exact-completion cactus plots", "file" => "figures/completion_cactus.svg", "source" => basename(paths.algorithm_rows)),
            Dict("registered_item" => "capability-carrier multiplicity versus compression", "file" => "figures/carrier_multiplicity_compression.svg", "source" => "$(basename(paths.carrier_multiplicity));$(basename(paths.instance_rows))"),
            Dict("registered_item" => "schedule identity overlap", "file" => "figures/schedule_identity_overlap.svg", "source" => basename(paths.overlap)),
            Dict("registered_item" => "postdecision diagnostics", "file" => "figures/postdecision_diagnostics.svg", "source" => basename(paths.algorithm_rows)),
        ],
        "storage_policy" => "normalized Snappy Parquet sources plus compact editable SVG; no duplicated raster figures",
        "raw_licensed_rows_included" => false,
    )
end

function _analysis_report(
    rows,
    instances,
    summaries,
    overlaps,
    agreements,
    carriers,
    reused,
)
    failures = count(row -> row.instance_status != "SUCCESS", rows) ÷ length(ALGORITHM_IDS)
    candidates = count(row -> row.candidate_returned, rows)
    postdecision = count(row -> row.postdecision_available, rows)
    overlap_available = count(row -> row.available, overlaps)
    return """# Financial Strategy-Library Panel v1 — audited analysis record

Generated at `$(_utc_now())` from the passing committed-schema local result audit.

- Registered algorithm rows: $(length(rows))
- Registered instance rows: $(length(instances))
- Registered instance failures retained: $failures
- Exactly feasible candidate rows: $candidates
- Available postdecision diagnostic rows: $postdecision
- Structural summary groups: $(length(summaries))
- Identity-overlap rows: $(length(overlaps)) ($overlap_available available)
- Exact-method agreement rows: $(length(agreements))
- Tagged-requirement carrier rows: $(length(carriers))
- Resumed Parquet partitions: $reused of 180

The normalized machine-readable tables are `algorithm_rows.parquet`,
`instance_rows.parquet`, `structural_summary.parquet`,
`identity_overlap.parquet`, `exact_method_agreement.parquet`, and
`carrier_multiplicity.parquet`. Exact burden and gap values remain encoded as
rational strings beside floating-point analysis columns. The carrier table
contains counts and tagged requirement types, not raw or identifying licensed
rows. Failures and inapplicable algorithms remain in denominators.

`ANALYSIS_CATALOG.toml` maps all seven registered tables and five registered
figures to these normalized sources. Figures are editable, accessible SVGs;
they add no duplicated raster payload and use markers, openness, line style, or
direct labels in addition to color.

Postdecision diagnostics are retrospective and postselection. They make no
causal, forecasting, alpha, or deployable-performance claim.
"""
end

function run_analysis(; progress_io = stderr)
    config, _, paths, audit = audit_ready()
    result_audit_sha256 = sha256_file(paths.result_audit)
    execution_lock = String(audit["execution_lock_aggregate_sha256"])
    stems = sort!(String[
        "$(origin_id)__$(library_id)__$(schedule_id)" for
        (origin_id, library_id, schedule_id) in registered_job_keys()
    ])
    reused = _write_partitions(
        stems,
        paths,
        result_audit_sha256,
        execution_lock;
        progress_io,
    )
    rows = _combine_partitions(stems, paths)
    instances = _instance_rows(rows)
    summaries = _summary_rows(rows)
    overlaps = _overlap_rows(rows)
    agreements = _agreement_rows(rows)
    carriers = _carrier_rows(stems, paths)
    atomic_write_parquet(
        paths.instance_rows,
        _column_table(instances, INSTANCE_SCHEMA);
        replace = true,
    )
    atomic_write_parquet(paths.summary, _column_table(summaries, SUMMARY_SCHEMA); replace = true)
    atomic_write_parquet(paths.overlap, _column_table(overlaps, OVERLAP_SCHEMA); replace = true)
    atomic_write_parquet(
        paths.exact_agreement,
        _column_table(agreements, AGREEMENT_SCHEMA);
        replace = true,
    )
    atomic_write_parquet(
        paths.carrier_multiplicity,
        _column_table(carriers, CARRIER_SCHEMA);
        replace = true,
    )
    figure_paths = _analysis_figures(rows, instances, overlaps, carriers, paths)
    _atomic_toml(paths.catalog, _analysis_catalog(paths); replace = true)
    _atomic_text(
        paths.report,
        _analysis_report(rows, instances, summaries, overlaps, agreements, carriers, reused);
        replace = true,
    )
    artifact_paths = [
        paths.algorithm_rows,
        paths.instance_rows,
        paths.summary,
        paths.overlap,
        paths.exact_agreement,
        paths.carrier_multiplicity,
        paths.catalog,
        paths.report,
    ]
    append!(artifact_paths, figure_paths)
    for stem in stems
        partition = _partition_paths(paths, stem)
        append!(artifact_paths, [partition.parquet, partition.metadata])
    end
    hashes = Dict(relpath(path, paths.analysis) => sha256_file(path) for path in artifact_paths)
    aggregate = _sha256_text(join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    ))
    manifest = Dict{String,Any}(
        "schema_version" => "financial-panel-analysis-manifest-v1",
        "experiment_id" => "financial-strategy-library-panel-v1",
        "created_at_utc" => _utc_now(),
        "execution_lock_aggregate_sha256" => execution_lock,
        "result_audit_sha256" => result_audit_sha256,
        "result_audit_postdecision_aggregate_sha256" =>
            audit["postdecision_result_aggregate_sha256"],
        "analysis_thread_count" => Threads.nthreads(),
        "registered_instance_count" => 180,
        "registered_algorithm_row_count" => length(rows),
        "instance_row_count" => length(instances),
        "summary_row_count" => length(summaries),
        "identity_overlap_row_count" => length(overlaps),
        "exact_method_agreement_row_count" => length(agreements),
        "carrier_multiplicity_row_count" => length(carriers),
        "registered_table_count" => 7,
        "registered_figure_count" => length(figure_paths),
        "resumed_partition_count" => reused,
        "parquet_compression" => "SNAPPY",
        "exact_values_preserved_as_rational_strings" => true,
        "raw_licensed_rows_included" => false,
        "artifact_aggregate_sha256" => aggregate,
        "files" => hashes,
    )
    _atomic_toml(paths.manifest, manifest; replace = true)
    return manifest
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: analyze_financial_strategy_library_panel_v1.jl --check|--run",
    )
    mode = only(args)
    mode == "--check" && return println(
        "financial panel analysis ready: audit=",
        sha256_file(_paths(first(load_panel_config())).result_audit),
        ", threads=",
        Threads.nthreads(),
    )
    mode == "--run" && return println(
        "financial panel analysis complete: ",
        run_analysis()["artifact_aggregate_sha256"],
    )
    error("unknown mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    AnalyzeFinancialStrategyLibraryPanelV1.main()
end
