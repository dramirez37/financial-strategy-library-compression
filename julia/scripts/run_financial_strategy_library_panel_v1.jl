module RunFinancialStrategyLibraryPanelV1

using Dates
using LinearAlgebra
using SHA: sha256
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV1.jl"))
using .FinancialStrategyLibraryPanelV1

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution.jl"))
using .LockFinancialStrategyLibraryPanelV1Execution: verify_execution_lock

export main,
       prepare_instances,
       run_postdecision_phase,
       run_smoke,
       run_structural_phase,
       validate_readiness

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v1.toml",
)
const THREAD_COUNT = 8

_utc_now() = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _atomic_write(path, text; replace = false)
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid()).$(Threads.threadid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, path; force = replace)
    return path
end

_atomic_toml(path, payload; replace = false) =
    _atomic_write(path, toml_text(payload); replace)

function _paths(config)
    paths = config["paths"]
    local_data = joinpath(REPOSITORY_ROOT, String(paths["local_data_root"]))
    local_results = joinpath(REPOSITORY_ROOT, String(paths["local_results_root"]))
    return (
        local_data,
        local_results,
        instances = joinpath(local_results, "instances"),
        origin_metadata = joinpath(local_data, "origin_builds"),
        preparation_manifest = joinpath(local_results, "PREPARATION_MANIFEST.toml"),
        structural = joinpath(local_results, "structural"),
        solver_logs = joinpath(local_results, "solver_logs"),
        postdecision = joinpath(local_results, "postdecision"),
        environment = joinpath(local_results, "ENVIRONMENT.toml"),
    )
end

function _source_root(config)
    if haskey(ENV, "ALGOLIB_CRSP_ROOT") && !isempty(strip(ENV["ALGOLIB_CRSP_ROOT"]))
        root = ENV["ALGOLIB_CRSP_ROOT"]
        return isabspath(root) ? normpath(root) : normpath(joinpath(REPOSITORY_ROOT, root))
    end
    configured = String(config["source"]["repository_root_default"])
    return normpath(joinpath(REPOSITORY_ROOT, configured))
end

function _environment()
    LinearAlgebra.BLAS.set_num_threads(1)
    commit = try
        strip(read(`git -C $REPOSITORY_ROOT rev-parse HEAD`, String))
    catch
        "UNAVAILABLE"
    end
    status = try
        read(`git -C $REPOSITORY_ROOT status --porcelain=v1 --untracked-files=all`, String)
    catch
        "UNAVAILABLE"
    end
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-environment-v1",
        "recorded_at_utc" => _utc_now(),
        "git_commit" => commit,
        "dirty_worktree" => !isempty(strip(status)),
        "dirty_worktree_status_sha256" => bytes2hex(sha256(codeunits(status))),
        "julia_version" => string(VERSION),
        "julia_threads" => Threads.nthreads(),
        "blas_threads" => LinearAlgebra.BLAS.get_num_threads(),
        "highs_threads_per_model" => 1,
        "threaded_lane_count" => THREAD_COUNT,
        "dependency_manifest_sha256" =>
            _sha256_file(joinpath(REPOSITORY_ROOT, "julia", "Manifest.toml")),
        "operating_system" => string(Sys.KERNEL),
        "architecture" => string(Sys.ARCH),
        "logical_threads_visible" => Sys.CPU_THREADS,
        "licensed_rows_included" => false,
    )
end

function _progress_line(label, completed, total; width = 36)
    ratio = iszero(total) ? 1.0 : completed / total
    filled = clamp(floor(Int, ratio * width), 0, width)
    bar = repeat("█", filled) * repeat("░", width - filled)
    return "$(rpad(label, 14)) [$bar] $(lpad(completed, ndigits(total)))/$total"
end

function _run_threaded_lanes!(jobs, label, run_one; lanes = THREAD_COUNT)
    lanes <= Threads.nthreads() || error(
        "$label requires at least $lanes Julia threads; found $(Threads.nthreads())",
    )
    assignments = [Any[] for _ in 1:lanes]
    for (index, job) in enumerate(jobs)
        push!(assignments[mod1(index, lanes)], job)
    end
    events = Channel{NamedTuple}(max(length(jobs), 1))
    tasks = Task[]
    for lane in 1:lanes
        push!(tasks, Threads.@spawn begin
            for job in assignments[lane]
                try
                    run_one(job, lane)
                    put!(events, (passed = true, lane = lane, exception = nothing))
                catch exception
                    put!(events, (passed = false, lane = lane, exception = exception))
                end
            end
        end)
    end
    completed = 0
    failures = NamedTuple[]
    print(stderr, '\r', _progress_line(label, completed, length(jobs)))
    while completed < length(jobs)
        event = take!(events)
        event.passed || push!(failures, event)
        completed += 1
        print(stderr, '\r', _progress_line(label, completed, length(jobs)))
    end
    println(stderr)
    foreach(fetch, tasks)
    isempty(failures) || error(
        "$label failed in $(length(failures)) job(s); first lane=$(first(failures).lane): " *
        sprint(showerror, first(failures).exception),
    )
    return completed
end

function _instance_stem(origin_id, library_id, schedule_id)
    return "$(origin_id)__$(library_id)__$(schedule_id)"
end

function _read_instance(path)
    return open(path, "r") do io
        read_journal_compression_instance(io)
    end
end

function _registry_seed(origin_id, library_id)
    row = only(filter(
        item -> item.origin_id == origin_id && item.library_id == library_id,
        FinancialStrategyLibraryPanelV1.FinancialStrategyLibraryPanelV1Registries.seed_rows(),
    ))
    return string(row.multistart_seed)
end

function validate_readiness(; require_sources::Bool = true)
    verify_execution_lock()
    VERSION == v"1.12.6" || error("financial panel v1 requires Julia 1.12.6")
    Threads.nthreads() == THREAD_COUNT || error(
        "financial panel v1 requires --threads=$THREAD_COUNT; found $(Threads.nthreads())",
    )
    LinearAlgebra.BLAS.set_num_threads(1)
    LinearAlgebra.BLAS.get_num_threads() == 1 || error("BLAS must use one thread")
    config, amendment = load_panel_config()
    amendment["threading"]["julia_threads"] == THREAD_COUNT ||
        error("execution amendment thread count changed")
    if require_sources
        paths = source_paths(config, _source_root(config))
        missing = filter(!isfile, [paths.security_history; paths.daily_files])
        isempty(missing) || error(
            "licensed source files are missing. Set ALGOLIB_CRSP_ROOT to the licensed CRSP root.",
        )
    end
    return config, amendment
end

function _write_environment(paths)
    if isfile(paths.environment)
        environment = TOML.parsefile(paths.environment)
        environment["julia_version"] == string(VERSION) || error("saved environment Julia version differs")
        environment["julia_threads"] == THREAD_COUNT || error("saved environment thread count differs")
        return environment
    end
    environment = _environment()
    _atomic_toml(paths.environment, environment)
    return environment
end

function _origin_payload(origin)
    return Dict{String,Any}(
        "origin_id" => origin.origin_id,
        "decision_year" => origin.decision_year,
        "decision_date" => origin.decision_date,
        "construction_start" => origin.construction_start,
        "construction_end" => origin.construction_end,
        "compression_start" => origin.compression_start,
        "compression_end" => origin.compression_end,
        "postdecision_start" => origin.postdecision_start,
        "postdecision_end" => origin.postdecision_end,
        "candidate_count" => origin.candidate_count,
        "eligible_count" => origin.eligible_count,
        "selected_count" => length(origin.selected),
        "reference_permno" => origin.reference_permno,
        "selected" => [Dict(
            "permno" => row.permno,
            "ticker" => row.ticker,
            "security_name_sha256" => row.security_name_sha256,
            "median_close" => row.median_close,
            "median_dollar_volume" => row.median_dollar_volume,
            "preorigin_daily_rows" => row.preorigin_daily_rows,
            "compression_liquidity_rows" => row.compression_liquidity_rows,
            "invalid_liquidity_rows" => row.invalid_liquidity_rows,
        ) for row in origin.selected],
        "licensed_rows_included" => false,
    )
end

function prepare_instances()
    config, amendment = validate_readiness()
    output = _paths(config)
    _write_environment(output)
    raw_paths = source_paths(config, _source_root(config))
    universes = construct_origin_universes(config, raw_paths)
    series_by_origin = extract_origin_series(
        config,
        raw_paths.daily_files,
        universes;
        phase = :structural,
    )
    entries_lock = ReentrantLock()
    entries = Dict{String,String}()
    run_one = function(origin, lane)
        instances, metadata = build_origin_instances(
            origin,
            series_by_origin[origin.origin_id],
            config,
            amendment,
        )
        metadata["thread_lane"] = lane
        metadata["origin_universe"] = _origin_payload(origin)
        metadata_path = joinpath(output.origin_metadata, "$(origin.origin_id).toml")
        metadata_text = toml_text(metadata)
        if isfile(metadata_path)
            read(metadata_path, String) == metadata_text || error("origin metadata drift on resume")
        else
            _atomic_write(metadata_path, metadata_text)
        end
        local_entries = Dict{String,String}(relpath(metadata_path, output.local_results) => _sha256_file(metadata_path))
        for ((library_id, schedule_id), instance) in instances
            stem = _instance_stem(origin.origin_id, library_id, schedule_id)
            path = joinpath(output.instances, stem * ".toml")
            text = serialize_journal_compression_instance(instance)
            if isfile(path)
                read(path, String) == text || error("instance drift on resume: $stem")
            else
                _atomic_write(path, text)
            end
            local_entries[relpath(path, output.local_results)] = _sha256_file(path)
        end
        lock(entries_lock) do
            merge!(entries, local_entries)
        end
        return nothing
    end
    _run_threaded_lanes!(universes, "prepare", run_one)
    instance_count = count(name -> endswith(name, ".toml"), readdir(output.instances))
    instance_count == 180 || error("preparation produced $instance_count instances instead of 180")
    manifest = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-preparation-manifest-v1",
        "created_at_utc" => _utc_now(),
        "origin_count" => length(universes),
        "instance_count" => instance_count,
        "registered_algorithm_terminal_rows" => instance_count * 7,
        "source_root_recorded" => false,
        "return_values_used_for_universe_selection" => false,
        "structural_return_maps_origin_scoped" => true,
        "shared_cross_origin_return_map_created" => false,
        "postdecision_returns_opened" => false,
        "licensed_rows_included" => false,
        "files" => entries,
    )
    _atomic_toml(output.preparation_manifest, manifest; replace = isfile(output.preparation_manifest))
    return output.preparation_manifest
end

function _validate_preparation(output)
    isfile(output.preparation_manifest) || error("preparation manifest is absent")
    manifest = TOML.parsefile(output.preparation_manifest)
    manifest["instance_count"] == 180 || error("prepared instance count changed")
    manifest["postdecision_returns_opened"] === false || error("preparation opened postdecision returns")
    for (relative, expected) in manifest["files"]
        path = joinpath(output.local_results, relative)
        isfile(path) || error("prepared artifact is missing: $relative")
        _sha256_file(path) == expected || error("prepared artifact hash mismatch: $relative")
    end
    return manifest
end

function _failure_payload(job, instance, exception)
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-instance-failure-v1",
        "experiment_id" => "financial-strategy-library-panel-v1",
        "origin_id" => job.origin_id,
        "library_id" => job.library_id,
        "schedule_id" => job.schedule_id,
        "instance_sha256" => journal_compression_instance_sha256(instance),
        "terminal" => true,
        "algorithm_terminal_row_count" => 7,
        "registered_algorithm_ids" => collect(FinancialStrategyLibraryPanelV1.ALGORITHM_IDS),
        "failure_type" => string(typeof(exception)),
        "failure_message" => sprint(showerror, exception),
        "postdecision_opened" => false,
        "licensed_rows_included" => false,
    )
end

function run_structural_phase()
    config, _ = validate_readiness(; require_sources = false)
    output = _paths(config)
    _validate_preparation(output)
    _write_environment(output)
    jobs = [(
        origin_id,
        library_id,
        schedule_id,
        stem = _instance_stem(origin_id, library_id, schedule_id),
    ) for (origin_id, library_id, schedule_id) in registered_job_keys()]
    run_one = function(job, lane)
        instance_path = joinpath(output.instances, job.stem * ".toml")
        result_path = joinpath(output.structural, job.stem * ".toml")
        instance = _read_instance(instance_path)
        if isfile(result_path)
            saved = TOML.parsefile(result_path)
            saved["terminal"] === true || error("nonterminal saved result: $(job.stem)")
            if saved["schema_version"] == "financial-strategy-library-panel-instance-result-v1"
                audit_instance_result(instance, saved)["passed"] === true ||
                    error("saved result fails resume audit: $(job.stem)")
            end
            return nothing
        end
        payload = nothing
        logs = Dict{String,String}()
        try
            payload, logs = run_algorithm_suite(
                instance;
                origin_id = job.origin_id,
                library_id = job.library_id,
                schedule_id = job.schedule_id,
                config,
            )
            payload["thread_lane"] = lane
            payload["multistart_seed"] = _registry_seed(job.origin_id, job.library_id)
        catch exception
            payload = _failure_payload(job, instance, exception)
            payload["thread_lane"] = lane
        end
        for (algorithm_id, log) in logs
            log_path = joinpath(output.solver_logs, job.stem * "__$(algorithm_id).log")
            _atomic_write(log_path, log)
            payload["solver_log_sha256"] = _sha256_file(log_path)
            payload["solver_log_path"] = relpath(log_path, output.local_results)
        end
        _atomic_toml(result_path, payload)
        return nothing
    end
    _run_threaded_lanes!(jobs, "structural", run_one)
    return output.structural
end

function _origin_from_saved(payload)
    selected = NamedTuple[
        (
            permno = Int(row["permno"]),
            ticker = String(row["ticker"]),
            security_name_sha256 = String(row["security_name_sha256"]),
            median_close = Float64(row["median_close"]),
            median_dollar_volume = Float64(row["median_dollar_volume"]),
            preorigin_daily_rows = Int(row["preorigin_daily_rows"]),
            compression_liquidity_rows = Int(row["compression_liquidity_rows"]),
            invalid_liquidity_rows = Int(row["invalid_liquidity_rows"]),
        ) for row in payload["selected"]
    ]
    return OriginUniverse(
        String(payload["origin_id"]),
        Int(payload["decision_year"]),
        String(payload["decision_date"]),
        String(payload["construction_start"]),
        String(payload["construction_end"]),
        String(payload["compression_start"]),
        String(payload["compression_end"]),
        String(payload["postdecision_start"]),
        String(payload["postdecision_end"]),
        selected,
        Int(payload["candidate_count"]),
        Int(payload["eligible_count"]),
        Int(payload["reference_permno"]),
    )
end

function _source_identity_tokens(instance)
    return Set(
        join(split(string(instance.strategy_ids[index].id), '|')[3:end], '|') for
        index in eachindex(instance.strategy_ids) if !instance.mandatory[index]
    )
end

function run_postdecision_phase()
    config, amendment = validate_readiness()
    output = _paths(config)
    structural_audit_path = joinpath(output.local_results, "STRUCTURAL_AUDIT.toml")
    isfile(structural_audit_path) || error("structural audit is absent; run the audit before postdecision")
    structural_audit = TOML.parsefile(structural_audit_path)
    structural_audit["passed"] === true || error("structural audit did not pass")
    origin_payloads = Dict{String,Any}()
    origins = Dict{String,OriginUniverse}()
    thresholds = Dict{String,Vector{Float64}}()
    for origin_row in FinancialStrategyLibraryPanelV1.FinancialStrategyLibraryPanelV1Registries.origin_rows()
        path = joinpath(output.origin_metadata, "$(origin_row.origin_id).toml")
        payload = TOML.parsefile(path)
        origin_payload = payload["origin_universe"]
        origin_payloads[origin_row.origin_id] = payload
        origins[origin_row.origin_id] = _origin_from_saved(origin_payload)
        thresholds[origin_row.origin_id] = Float64.(payload["belief_thresholds"])
    end
    raw_paths = source_paths(config, _source_root(config))
    series_by_origin = extract_origin_series(
        config,
        raw_paths.daily_files,
        collect(values(origins));
        phase = :postdecision,
    )
    jobs = [(
        origin_id,
        library_id,
        schedule_id,
        stem = _instance_stem(origin_id, library_id, schedule_id),
    ) for (origin_id, library_id, schedule_id) in registered_job_keys()]
    run_one = function(job, lane)
        destination = joinpath(output.postdecision, job.stem * ".toml")
        isfile(destination) && return nothing
        instance = _read_instance(joinpath(output.instances, job.stem * ".toml"))
        result_payload = TOML.parsefile(joinpath(output.structural, job.stem * ".toml"))
        payload = if result_payload["schema_version"] ==
                     "financial-strategy-library-panel-instance-result-v1"
            next_year = origins[job.origin_id].decision_year + 1
            next_origin_id = next_year <= 2024 ? "FSLP1-O$next_year" : nothing
            next_identities = if isnothing(next_origin_id)
                nothing
            else
                next_stem = _instance_stem(next_origin_id, job.library_id, job.schedule_id)
                _source_identity_tokens(_read_instance(joinpath(output.instances, next_stem * ".toml")))
            end
            evaluate_postdecision(
                instance,
                result_payload,
                origins[job.origin_id],
                series_by_origin[job.origin_id],
                thresholds[job.origin_id],
                config,
                amendment;
                next_origin_source_identities = next_identities,
            )
        else
            Dict{String,Any}(
                "schema_version" => "financial-strategy-library-panel-postdecision-failure-v1",
                "origin_id" => job.origin_id,
                "library_id" => job.library_id,
                "schedule_id" => job.schedule_id,
                "available" => false,
                "reason" => "structural instance failure",
                "structural_result_terminal_and_audited_before_open" => true,
                "licensed_rows_included" => false,
            )
        end
        payload["thread_lane"] = lane
        _atomic_toml(destination, payload)
        return nothing
    end
    _run_threaded_lanes!(jobs, "postdecision", run_one)
    return output.postdecision
end

function run_smoke()
    config, _ = validate_readiness(; require_sources = false)
    jobs = build_synthetic_smoke_instances(THREAD_COUNT)
    mktempdir() do root
        run_one = function(job, lane)
            payload, logs = run_algorithm_suite(
                job.instance;
                origin_id = job.origin_id,
                library_id = job.library_id,
                schedule_id = job.schedule_id,
                config,
            )
            audit = audit_instance_result(job.instance, payload)
            audit["passed"] === true || error("synthetic smoke exact audit failed")
            payload["thread_lane"] = lane
            path = joinpath(root, "$(job.origin_id).toml")
            _atomic_toml(path, payload)
            TOML.parsefile(path)["algorithm_terminal_row_count"] == 7 ||
                error("synthetic smoke serialization failed")
            haskey(logs, "jump_highs_tagged_cover") || error("synthetic smoke lost HiGHS log")
        end
        _run_threaded_lanes!(jobs, "smoke", run_one)
        count(name -> endswith(name, ".toml"), readdir(root)) == THREAD_COUNT ||
            error("threaded smoke did not produce one record per lane")
    end
    println("financial panel v1 threaded smoke passed: lanes=8, algorithms_per_lane=7")
    return true
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: run_financial_strategy_library_panel_v1.jl --check|--smoke|--prepare-only|--solve-only|--postdecision-only|--run",
    )
    mode = only(args)
    if mode == "--check"
        config, amendment = validate_readiness()
        experiment_id = config["experiment_id"]
        amendment_id = amendment["amendment_id"]
        println(
            "financial panel v1 runner ready: experiment=$experiment_id, " *
            "amendment=$amendment_id, threads=$(Threads.nthreads())",
        )
        return true
    end
    mode == "--smoke" && return run_smoke()
    mode == "--prepare-only" && return prepare_instances()
    mode == "--solve-only" && return run_structural_phase()
    mode == "--postdecision-only" && return run_postdecision_phase()
    if mode == "--run"
        prepare_instances()
        run_structural_phase()
        Base.include(Main, joinpath(@__DIR__, "audit_financial_strategy_library_panel_v1.jl"))
        Main.AuditFinancialStrategyLibraryPanelV1.audit_structural_results()
        run_postdecision_phase()
        return Main.AuditFinancialStrategyLibraryPanelV1.audit_all_results()
    end
    error("unknown mode: $mode")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    RunFinancialStrategyLibraryPanelV1.main()
end
