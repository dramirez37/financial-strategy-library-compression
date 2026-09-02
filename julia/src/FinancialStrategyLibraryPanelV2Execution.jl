module FinancialStrategyLibraryPanelV2Execution

using Dates
using LinearAlgebra
using Random: randperm
using SHA: sha256
using StableRNGs: StableRNG
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "FinancialStrategyLibraryPanelV1.jl"))
using .FinancialStrategyLibraryPanelV1

include(joinpath(@__DIR__, "..", "scripts", "create_financial_strategy_library_panel_v2_flagship_registries.jl"))
using .FinancialStrategyLibraryPanelV2FlagshipRegistries
const FinancialStrategyLibraryPanelV2Registries =
    FinancialStrategyLibraryPanelV2FlagshipRegistries

export load_execution_config,
       run_all,
       run_synthetic_smoke,
       run_structural_smoke,
       source_metadata,
       verify_predecision_seal

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = get(
    ENV,
    "ALGOLIB_FINANCIAL_PANEL_CONFIG_PATH",
    joinpath(
        REPOSITORY_ROOT,
        "experiments",
        "configs",
        "financial_strategy_library_panel_v2.toml",
    ),
)
const CONFIG_OVERRIDE_PATH = get(
    ENV,
    "ALGOLIB_FINANCIAL_PANEL_CONFIG_OVERRIDE_PATH",
    "",
)
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2",
)
const DESIGN_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK.json")
const EXECUTION_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK.json")
const EXECUTION_LOCK_002_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_002.json")
const EXECUTION_LOCK_003_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_003.json")
const EXECUTION_LOCK_004_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_004.json")
const EXECUTION_LOCK_005_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_005.json")
const EXECUTION_LOCK_006_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_006.json")
const EXECUTION_LOCK_007_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_007.json")
const EXECUTION_LOCK_008_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_008.json")
const EXECUTION_LOCK_009_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_009.json")
const EXECUTION_LOCK_010_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_010.json")
const EXECUTION_LOCK_011_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_011.json")
const LOCAL_DATA_ROOT = joinpath(EXPERIMENT_ROOT, "local_data")
const LOCAL_RESULTS_ROOT = joinpath(EXPERIMENT_ROOT, "local_results")
const PREDECISION_ROOT = joinpath(LOCAL_RESULTS_ROOT, "predecision")
const POSTDECISION_ROOT = joinpath(LOCAL_RESULTS_ROOT, "postdecision")
const ANALYSIS_ROOT = joinpath(LOCAL_RESULTS_ROOT, "analysis")
const PRIMARY_SCHEDULE = "validation_work_units"
const REQUIRED_EXECUTION_LOCK_SCHEMA =
    "financial-strategy-library-panel-v2-execution-lock-v1"
const KNOWN_CRSP_MISSING_RETURN_FLAGS = Set((
    "DG",
    "DM",
    "DP",
    "GP",
    "MP",
    "MV",
    "NS",
    "NT",
    "RA",
))
const STUDY_START = "2000-01-01"
const STUDY_END = "2025-12-31"
const MASTER_CHUNK_ROWS = 250_000
const ELIGIBLE_PRIMARY_EXCHANGES = Set(("N", "Q", "A", "R", "B"))
const REQUIRED_MARKET_HISTORY_COLUMNS = (
    "permno",
    "secinfostartdt",
    "secinfoenddt",
    "ticker",
    "securitynm",
    "primaryexch",
    "conditionaltype",
    "tradingstatusflg",
    "usincflg",
    "issuertype",
    "securitytype",
    "securitysubtype",
    "sharetype",
)

struct V2MarketInterval
    permno::Int
    start_date::String
    end_date::String
    ticker::String
    security_name::String
    primary_exchange::String
    conditional_type::String
    trading_status::String
    us_incorporated::String
    issuer_type::String
    security_type::String
    security_subtype::String
    share_type::String
end

_utc_now() = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
_sha256_text(text::AbstractString) = bytes2hex(sha256(codeunits(text)))
_sha256_file(path::AbstractString) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_exact_text(value::Rational) = "$(numerator(value))//$(denominator(value))"
_float_exact(value::Float64) = rationalize(BigInt, value; tol = 0)

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _atomic_toml(path::AbstractString, payload; replace::Bool = false)
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid()).$(Threads.threadid())"
    open(temporary, "w") do io
        write(io, _toml_text(payload))
    end
    mv(temporary, path; force = replace)
    return path
end

function _directory_hashes(directory::AbstractString)
    entries = Dict{String,String}()
    isdir(directory) || return entries
    for (root, _, files) in walkdir(directory), file in files
        path = joinpath(root, file)
        entries[relpath(path, directory)] = _sha256_file(path)
    end
    return entries
end

function _directory_aggregate_from_hashes(entries::AbstractDict)
    canonical = join(
        ("$path\0$(entries[path])\n" for path in sort!(collect(keys(entries)))),
    )
    return _sha256_text(canonical)
end

_directory_aggregate(directory::AbstractString) =
    _directory_aggregate_from_hashes(_directory_hashes(directory))

function _require_execution_lock()
    path = isfile(EXECUTION_LOCK_011_PATH) ? EXECUTION_LOCK_011_PATH :
           isfile(EXECUTION_LOCK_010_PATH) ? EXECUTION_LOCK_010_PATH :
           isfile(EXECUTION_LOCK_009_PATH) ? EXECUTION_LOCK_009_PATH :
           isfile(EXECUTION_LOCK_008_PATH) ? EXECUTION_LOCK_008_PATH :
           isfile(EXECUTION_LOCK_007_PATH) ? EXECUTION_LOCK_007_PATH :
           isfile(EXECUTION_LOCK_006_PATH) ? EXECUTION_LOCK_006_PATH :
           isfile(EXECUTION_LOCK_005_PATH) ? EXECUTION_LOCK_005_PATH :
           isfile(EXECUTION_LOCK_004_PATH) ? EXECUTION_LOCK_004_PATH :
           isfile(EXECUTION_LOCK_003_PATH) ? EXECUTION_LOCK_003_PATH :
           isfile(EXECUTION_LOCK_002_PATH) ? EXECUTION_LOCK_002_PATH : EXECUTION_LOCK_PATH
    isfile(path) || error("v2 execution lock is absent")
    text = read(path, String)
    valid_schema = occursin("\"schema_version\": \"$REQUIRED_EXECUTION_LOCK_SCHEMA\"", text) ||
                   occursin("\"schema_version\": \"financial-strategy-library-panel-v2-execution-lock-v2\"", text) ||
                   occursin("\"schema_version\": \"financial-strategy-library-panel-v2-execution-lock-v3\"", text) ||
                   occursin("\"schema_version\": \"financial-strategy-library-panel-v2-execution-lock-v4\"", text) ||
                   occursin("\"schema_version\": \"financial-strategy-library-panel-v2-execution-lock-v5\"", text) ||
                   occursin("\"schema_version\": \"financial-strategy-library-panel-v2-execution-lock-v6\"", text) ||
                   occursin("\"schema_version\": \"financial-strategy-library-panel-v2-execution-lock-v7\"", text) ||
                   occursin("\"schema_version\": \"financial-strategy-library-panel-v2-execution-lock-v8\"", text) ||
                   occursin("\"schema_version\": \"financial-strategy-library-panel-v2-execution-lock-v9\"", text) ||
                   occursin("\"schema_version\": \"financial-strategy-library-panel-v2-execution-lock-v10\"", text) ||
                   occursin("\"schema_version\": \"financial-strategy-library-panel-v2-execution-lock-v11\"", text)
    valid_schema ||
        error("unexpected v2 execution-lock schema")
    match = Base.match(r"\"aggregate_sha256\": \"([0-9a-f]{64})\"", text)
    isnothing(match) && error("v2 execution lock has no aggregate digest")
    return only(match.captures)
end

function _merge_config!(base::Dict{String,Any}, override::Dict{String,Any})
    for (key, value) in override
        key == "override_schema_version" && continue
        if value isa Dict && get(base, key, nothing) isa Dict
            _merge_config!(base[key], value)
        else
            base[key] = value
        end
    end
    return base
end

function load_execution_config()
    config = TOML.parsefile(CONFIG_PATH)
    config["schema_version"] == "financial-strategy-library-panel-design-v2" ||
        error("unsupported v2 design schema")
    if !isempty(CONFIG_OVERRIDE_PATH)
        override = TOML.parsefile(CONFIG_OVERRIDE_PATH)
        override["override_schema_version"] ==
            "financial-strategy-library-panel-v2-flagship-override-v1" ||
            error("unsupported financial-panel flagship override schema")
        _merge_config!(config, override)
    end
    if haskey(config["innovation_challenges"], "seed_namespace")
        config["innovation_challenges"]["seed_namespace"] ==
            FinancialStrategyLibraryPanelV2Registries.seed_namespace() ||
            error("runtime seed namespace differs from the locked flagship design")
        seed_path = joinpath(
            REPOSITORY_ROOT,
            String(config["innovation_challenges"]["seed_registry"]),
        )
        isfile(seed_path) || error("flagship seed registry is absent")
        read(seed_path, String) == FinancialStrategyLibraryPanelV2Registries._render_csv(
            FinancialStrategyLibraryPanelV2Registries.seed_rows(),
        ) || error("flagship seed registry differs from deterministic fresh-seed generation")
    end
    return config
end

function _runtime_config(config; cost_bps::Integer = 5, risk_aversion::Integer = 3)
    runtime = deepcopy(config)
    runtime["operating_profiles"]["one_way_transaction_cost_bps"] = Int(cost_bps)
    runtime["operating_profiles"]["risk_aversion"] = Int(risk_aversion)
    runtime["operating_profiles"]["minimum_profile_observations"] =
        Int(config["universe"]["minimum_construction_observations_per_belief"])
    runtime["grammar"]["strategies_per_instrument_full_factorial"] =
        Int(config["grammar"]["strategies_per_instrument"])
    runtime["universe"]["minimum_eligible_for_analysis"] =
        Int(config["universe"]["minimum_eligible_for_origin"])
    return runtime
end

_runtime_amendment() = Dict{String,Any}(
    "lookbacks" => Dict{String,Any}(
        "belief_sessions" => 60,
        "trend_filter_sessions" => 100,
        "volatility_sessions" => 20,
    ),
)

function _source_root(config)
    if haskey(ENV, "ALGOLIB_CRSP_ROOT") && !isempty(strip(ENV["ALGOLIB_CRSP_ROOT"]))
        root = ENV["ALGOLIB_CRSP_ROOT"]
        return isabspath(root) ? normpath(root) : normpath(joinpath(REPOSITORY_ROOT, root))
    end
    return normpath(joinpath(REPOSITORY_ROOT, String(config["source"]["repository_root_default"])))
end

function source_metadata(config = load_execution_config())
    paths = FinancialStrategyLibraryPanelV1.source_paths(config, _source_root(config))
    files = [paths.security_history; paths.daily_files]
    all(isfile, files) || error("one or more registered CRSP source files are absent")
    return (
        paths,
        files = [(
            path = path,
            relative_role = path == paths.security_history ? "security_history" :
                "daily_$(findfirst(==(path), paths.daily_files))",
            byte_size = filesize(path),
            modified_unix_seconds = round(Int, stat(path).mtime),
        ) for path in files],
    )
end

function _instrument_class(interval::V2MarketInterval)
    interval.conditional_type == "RW" || return ""
    interval.trading_status == "A" || return ""
    interval.us_incorporated == "Y" || return ""
    interval.share_type == "NS" || return ""
    interval.primary_exchange in ELIGIBLE_PRIMARY_EXCHANGES || return ""
    if interval.security_type == "EQTY" && interval.security_subtype == "COM" &&
       interval.issuer_type in ("ACOR", "CORP")
        return "common_equity"
    end
    if interval.security_type == "FUND" && interval.security_subtype == "ETF"
        return "plain_etf"
    end
    return ""
end

function _load_market_intervals(path)
    intervals = V2MarketInterval[]
    open(path, "r") do io
        header = strip.(FinancialStrategyLibraryPanelV1._split_csv(chomp(readline(io))))
        positions = FinancialStrategyLibraryPanelV1._positions(
            header,
            collect(REQUIRED_MARKET_HISTORY_COLUMNS),
        )
        for line in eachline(io)
            fields = FinancialStrategyLibraryPanelV1._split_csv(chomp(line))
            length(fields) == length(header) || error("security-history CSV width mismatch")
            permno = tryparse(Int, strip(fields[positions["permno"]]))
            isnothing(permno) && continue
            interval = V2MarketInterval(
                permno,
                strip(fields[positions["secinfostartdt"]]),
                strip(fields[positions["secinfoenddt"]]),
                strip(fields[positions["ticker"]]),
                strip(fields[positions["securitynm"]]),
                strip(fields[positions["primaryexch"]]),
                strip(fields[positions["conditionaltype"]]),
                strip(fields[positions["tradingstatusflg"]]),
                strip(fields[positions["usincflg"]]),
                strip(fields[positions["issuertype"]]),
                strip(fields[positions["securitytype"]]),
                strip(fields[positions["securitysubtype"]]),
                strip(fields[positions["sharetype"]]),
            )
            interval.start_date <= interval.end_date ||
                error("security-history interval has reversed dates")
            push!(intervals, interval)
        end
    end
    return intervals
end

_interval_intersects_study(interval::V2MarketInterval) =
    interval.start_date <= STUDY_END && STUDY_START <= interval.end_date

function _master_target_permnos(intervals)
    return Set(
        interval.permno for interval in intervals if
        _interval_intersects_study(interval) && !isempty(_instrument_class(interval))
    )
end

function _write_market_interval_artifact(intervals, target_permnos, execution_lock_aggregate)
    selected = sort!(
        [interval for interval in intervals if interval.permno in target_permnos];
        by = interval -> (interval.permno, interval.start_date, interval.end_date),
    )
    columns = (
        permno = Int64[interval.permno for interval in selected],
        start_date = String[interval.start_date for interval in selected],
        end_date = String[interval.end_date for interval in selected],
        ticker = String[interval.ticker for interval in selected],
        security_name = String[interval.security_name for interval in selected],
        primary_exchange = String[interval.primary_exchange for interval in selected],
        conditional_type = String[interval.conditional_type for interval in selected],
        trading_status = String[interval.trading_status for interval in selected],
        us_incorporated = String[interval.us_incorporated for interval in selected],
        issuer_type = String[interval.issuer_type for interval in selected],
        security_type = String[interval.security_type for interval in selected],
        security_subtype = String[interval.security_subtype for interval in selected],
        share_type = String[interval.share_type for interval in selected],
        instrument_class = String[_instrument_class(interval) for interval in selected],
    )
    path = joinpath(LOCAL_DATA_ROOT, "master_market_panel", "security_intervals.parquet")
    FinancialStrategyLibraryPanelV1.atomic_write_parquet(path, columns; replace = false)
    _atomic_toml(joinpath(LOCAL_DATA_ROOT, "master_market_panel", "security_intervals.toml"), Dict(
        "schema_version" => "financial-panel-v2-market-intervals-v1",
        "study_start" => STUDY_START,
        "study_end" => STUDY_END,
        "eligible_permno_count" => length(target_permnos),
        "retained_history_interval_count" => length(selected),
        "parquet_sha256" => _sha256_file(path),
        "execution_lock_aggregate_sha256" => execution_lock_aggregate,
        "local_licensed_rows_included" => true,
        "public_promotion_permitted" => false,
    ))
    return path
end

function _stage_master_market_file(
    config,
    path,
    target_permnos,
    root,
    file_index,
    file_count,
)
    required = String.(config["source"]["required_daily_columns"]["columns"])
    permnos = Int64[]
    dates = String[]
    returns = Union{Missing,Float64}[]
    closes = Union{Missing,Float64}[]
    volumes = Union{Missing,Float64}[]
    delisting_flags = String[]
    return_flags = String[]
    source_indices = Int64[]
    chunks = NamedTuple[]
    missing_flags = Dict{String,Int}()
    source_rows = 0
    retained_rows = 0
    valid_return_rows = 0
    flagged_finite_return_rows = 0
    invalid_close_rows = 0
    invalid_volume_rows = 0
    chunk_index = 0
    last_date = Dict{Int,String}()
    function flush_chunk!()
        isempty(permnos) && return
        chunk_index += 1
        name = "daily-source-$(lpad(file_index, 3, '0'))-chunk-$(lpad(chunk_index, 5, '0')).parquet"
        chunk_path = joinpath(root, name)
        columns = (
            permno = permnos,
            date = dates,
            total_return = returns,
            close = closes,
            volume = volumes,
            delisting_flag = delisting_flags,
            return_flag = return_flags,
            source_row_index = source_indices,
        )
        row_count = length(permnos)
        FinancialStrategyLibraryPanelV1.atomic_write_parquet(
            chunk_path,
            columns;
            replace = false,
        )
        push!(chunks, (;
            file_index,
            chunk_index,
            name,
            row_count,
            sha256 = _sha256_file(chunk_path),
        ))
        empty!(permnos)
        empty!(dates)
        empty!(returns)
        empty!(closes)
        empty!(volumes)
        empty!(delisting_flags)
        empty!(return_flags)
        empty!(source_indices)
    end
    _progress("parallel master-panel staging started file $file_index/$file_count")
    FinancialStrategyLibraryPanelV1._with_daily_file(path) do io
        header = strip.(FinancialStrategyLibraryPanelV1._split_csv(chomp(readline(io))))
        positions = FinancialStrategyLibraryPanelV1._positions(header, required)
        for line in eachline(io)
            source_rows += 1
            source_rows % 5_000_000 == 0 && _progress(
                "parallel master-panel staging file $file_index rows=$source_rows chunks=$chunk_index",
            )
            fields = FinancialStrategyLibraryPanelV1._split_csv(chomp(line))
            length(fields) == length(header) || error("daily-security CSV width mismatch")
            permno = tryparse(Int, strip(fields[positions["permno"]]))
            isnothing(permno) && continue
            permno in target_permnos || continue
            date = strip(fields[positions["dlycaldt"]])
            STUDY_START <= date <= STUDY_END || continue
            date > get(last_date, permno, "") ||
                error("duplicate or unstable file-local master-panel ordering")
            last_date[permno] = date
            total_return = FinancialStrategyLibraryPanelV1._parse_float(fields[positions["dlyret"]])
            return_flag = strip(fields[positions["dlyretmissflg"]])
            if isnothing(total_return)
                _known_missing_return_flag(return_flag) || error(
                    "master panel found an unknown or contradictory missing-return flag",
                )
                missing_flags[return_flag] = get(missing_flags, return_flag, 0) + 1
            else
                total_return >= -1 || error("master panel found a return below total loss")
                return_flag in ("NA", "MV") || error(
                    "master panel found a finite return with an unknown return-quality flag",
                )
                return_flag == "NA" ? (valid_return_rows += 1) :
                    (flagged_finite_return_rows += 1)
            end
            close = FinancialStrategyLibraryPanelV1._positive_close(fields, positions)
            volume = FinancialStrategyLibraryPanelV1._parse_float(fields[positions["dlyvol"]])
            invalid_volume = isnothing(volume) || volume < 0
            isnothing(close) && (invalid_close_rows += 1)
            invalid_volume && (invalid_volume_rows += 1)
            push!(permnos, Int64(permno))
            push!(dates, date)
            push!(returns, isnothing(total_return) ? missing : total_return)
            push!(closes, isnothing(close) ? missing : close)
            push!(volumes, invalid_volume ? missing : volume)
            push!(delisting_flags, strip(fields[positions["dlydelflg"]]))
            push!(return_flags, return_flag)
            push!(source_indices, Int64(source_rows))
            retained_rows += 1
            length(permnos) >= MASTER_CHUNK_ROWS && flush_chunk!()
        end
    end
    flush_chunk!()
    quality = Dict{String,Any}(
        "source_file_index" => file_index,
        "source_file_basename" => basename(path),
        "source_rows_scanned" => source_rows,
        "retained_master_rows" => retained_rows,
        "valid_return_rows" => valid_return_rows,
        "flagged_finite_return_rows" => flagged_finite_return_rows,
        "known_missing_return_rows" => sum(values(missing_flags); init = 0),
        "known_missing_return_flags" => missing_flags,
        "invalid_close_rows" => invalid_close_rows,
        "invalid_volume_rows" => invalid_volume_rows,
        "chunk_count" => length(chunks),
    )
    _progress(
        "parallel master-panel staging completed file $file_index/$file_count " *
        "source_rows=$source_rows retained=$retained_rows chunks=$(length(chunks))",
    )
    return chunks, quality
end

function _stage_master_market_panel(
    config,
    daily_files,
    intervals,
    execution_lock_aggregate,
)
    Threads.nthreads() > 1 || error("master-panel staging requires multiple Julia threads")
    root = joinpath(LOCAL_DATA_ROOT, "master_market_panel")
    !ispath(root) || error("immutable master-market-panel directory already exists")
    mkpath(root)
    target_permnos = _master_target_permnos(intervals)
    isempty(target_permnos) && error("master market universe is empty")
    _write_market_interval_artifact(intervals, target_permnos, execution_lock_aggregate)
    file_chunks = Vector{Any}(undef, length(daily_files))
    file_quality = Vector{Any}(undef, length(daily_files))
    errors = Vector{Union{Nothing,String}}(undef, length(daily_files))
    fill!(errors, nothing)
    Threads.@threads :static for file_index in eachindex(daily_files)
        try
            file_chunks[file_index], file_quality[file_index] = _stage_master_market_file(
                config,
                daily_files[file_index],
                target_permnos,
                root,
                file_index,
                length(daily_files),
            )
        catch exception
            errors[file_index] = sprint(showerror, exception)
        end
    end
    failed = findall(!isnothing, errors)
    isempty(failed) || error(join(("file $index: $(errors[index])" for index in failed), "; "))
    chunks = reduce(vcat, file_chunks; init = NamedTuple[])
    sort!(chunks; by = chunk -> (chunk.file_index, chunk.chunk_index))
    manifest = Dict{String,Any}(
        "schema_version" => "financial-panel-v2-master-market-panel-v1",
        "study_start" => STUDY_START,
        "study_end" => STUDY_END,
        "instrument_classes" => ["common_equity", "plain_etf"],
        "eligible_permno_count" => length(target_permnos),
        "source_file_count" => length(daily_files),
        "chunk_row_limit" => MASTER_CHUNK_ROWS,
        "chunk_count" => length(chunks),
        "retained_master_rows" => sum(item["retained_master_rows"] for item in file_quality),
        "execution_lock_aggregate_sha256" => execution_lock_aggregate,
        "source_quality" => file_quality,
        "chunks" => [Dict{String,Any}(
            "source_file_index" => chunk.file_index,
            "chunk_index" => chunk.chunk_index,
            "path" => chunk.name,
            "row_count" => chunk.row_count,
            "sha256" => chunk.sha256,
        ) for chunk in chunks],
        "local_licensed_rows_included" => true,
        "public_promotion_permitted" => false,
    )
    _atomic_toml(joinpath(root, "MASTER_MANIFEST.toml"), manifest)
    return [joinpath(root, chunk.name) for chunk in chunks], intervals, manifest
end

function _reuse_master_market_panel(config, daily_files, intervals)
    root = joinpath(LOCAL_DATA_ROOT, "master_market_panel")
    reuse = config["master_panel"]
    manifest_path = joinpath(root, "MASTER_MANIFEST.toml")
    isfile(manifest_path) || error("adopted master-market-panel manifest is absent")
    _sha256_file(manifest_path) == String(reuse["adopted_manifest_sha256"]) ||
        error("adopted master-market-panel manifest digest changed")
    file_hashes = _directory_hashes(root)
    observed_aggregate = _directory_aggregate_from_hashes(file_hashes)
    observed_aggregate == String(reuse["adopted_directory_aggregate_sha256"]) ||
        error("adopted master-market-panel directory aggregate changed")
    manifest = TOML.parsefile(manifest_path)
    manifest["schema_version"] == "financial-panel-v2-master-market-panel-v1" ||
        error("unsupported adopted master-market-panel schema")
    manifest["study_start"] == STUDY_START || error("adopted master-panel start changed")
    manifest["study_end"] == STUDY_END || error("adopted master-panel end changed")
    manifest["source_file_count"] == length(daily_files) ||
        error("adopted master-panel source-file count changed")
    manifest["execution_lock_aggregate_sha256"] ==
        String(reuse["source_execution_lock_aggregate_sha256"]) ||
        error("adopted master-panel source execution lock changed")
    manifest["chunk_count"] == length(manifest["chunks"]) ||
        error("adopted master-panel chunk count is inconsistent")
    manifest["chunk_count"] == Int(reuse["expected_chunk_count"]) ||
        error("adopted master-panel chunk count differs from the successor lock")
    manifest["retained_master_rows"] ==
        sum(Int(chunk["row_count"]) for chunk in manifest["chunks"]) ||
        error("adopted master-panel row count is inconsistent")
    manifest["retained_master_rows"] == Int(reuse["expected_retained_rows"]) ||
        error("adopted master-panel row count differs from the successor lock")
    interval_manifest = TOML.parsefile(joinpath(root, "security_intervals.toml"))
    _sha256_file(joinpath(root, "security_intervals.parquet")) ==
        interval_manifest["parquet_sha256"] ||
        error("adopted security-interval artifact digest changed")
    length(_master_target_permnos(intervals)) == manifest["eligible_permno_count"] ||
        error("adopted master-panel eligible identifier count changed")
    chunks = String[]
    seen = Set{String}()
    for chunk in manifest["chunks"]
        name = String(chunk["path"])
        basename(name) == name || error("adopted master-panel chunk path is not flat")
        name in seen && error("adopted master-panel manifest repeats a chunk")
        push!(seen, name)
        path = joinpath(root, name)
        isfile(path) || error("adopted master-panel chunk is absent: $name")
        file_hashes[name] == String(chunk["sha256"]) ||
            error("adopted master-panel chunk digest is internally inconsistent: $name")
        push!(chunks, path)
    end
    expected_files = union(
        seen,
        Set(("MASTER_MANIFEST.toml", "security_intervals.parquet", "security_intervals.toml")),
    )
    Set(keys(file_hashes)) == expected_files ||
        error("adopted master-panel contains an unregistered or missing file")
    length(file_hashes) == Int(reuse["expected_file_count"]) ||
        error("adopted master-panel file count differs from the successor lock")
    retained_rows = manifest["retained_master_rows"]
    chunk_count = manifest["chunk_count"]
    _progress(
        "adopted master panel verified: $retained_rows rows, " *
        "$chunk_count chunks, aggregate $observed_aggregate",
    )
    return chunks, intervals, manifest
end

function _progress(message)
    println(stderr, "[", _utc_now(), "] ", message)
    flush(stderr)
end

struct V2Evaluation
    strategy::FinancialStrategyLibraryPanelV1.PanelStrategy
    strategy_id::String
    construction_score::Float64
    predecision_score::Float64
    scenario_profile::Vector{Float64}
    validation_work_units::Int
    governance_review_units::Int
end

function _shrunk_regime_utility(
    state_utility::Real,
    pooled_utility::Real,
    state_sessions::Integer,
    prior_strength_sessions::Real,
)
    state_sessions >= 0 || throw(ArgumentError("state sessions must be nonnegative"))
    prior_strength_sessions >= 0 || throw(ArgumentError("prior strength must be nonnegative"))
    iszero(state_sessions) && return Float64(pooled_utility)
    weight = state_sessions / (state_sessions + prior_strength_sessions)
    return weight * Float64(state_utility) + (1 - weight) * Float64(pooled_utility)
end

mutable struct CompleteCaseStats
    observed_reference_sessions::Int
    missing_return_sessions::Int
    invalid_price_sessions::Int
    invalid_volume_sessions::Int
    nonreference_sessions::Int
    construction_profile_counts::Vector{Int}
    compression_profile_counts::Vector{Int}
end

CompleteCaseStats() = CompleteCaseStats(0, 0, 0, 0, 0, zeros(Int, 5), zeros(Int, 5))

function _canonical_specification(origin_id, permno, signal, filter, horizon, sizing, exit_rule, risk)
    return join((
        "schema=financial-panel-strategy-spec-v2",
        "origin=$origin_id",
        "permno=$permno",
        "signal=$signal",
        "filter=$filter",
        "horizon=$horizon",
        "sizing=$sizing",
        "exit=$exit_rule",
        "risk=$risk",
    ), '\n')
end

function _strategy(origin_id, permno, signal, filter, horizon, sizing, exit_rule, risk)
    capabilities = FinancialStrategyLibraryPanelV2Registries.capability_ids_for_spec(
        signal = String(signal),
        filter = String(filter),
        horizon = Int(horizon),
        sizing = String(sizing),
        exit_rule = String(exit_rule),
        risk = String(risk),
    )
    specification = _canonical_specification(
        origin_id,
        permno,
        signal,
        filter,
        horizon,
        sizing,
        exit_rule,
        risk,
    )
    return FinancialStrategyLibraryPanelV1.PanelStrategy(
        String(origin_id),
        Int(permno),
        String(signal),
        String(filter),
        Int(horizon),
        String(sizing),
        String(exit_rule),
        String(risk),
        Tuple(capabilities),
        _sha256_text(specification),
    )
end

_strategy_key(strategy) = (
    strategy.permno,
    strategy.directional_signal,
    strategy.entry_filter,
    strategy.holding_horizon,
    strategy.sizing_rule,
    strategy.exit_rule,
    strategy.risk_constraint,
)

_strategy_id(strategy) = join((
    strategy.origin_id,
    strategy.permno,
    strategy.directional_signal,
    strategy.entry_filter,
    strategy.holding_horizon,
    strategy.sizing_rule,
    strategy.exit_rule,
    strategy.risk_constraint,
), '|')

function _catalog(origin, config)
    grammar = config["grammar"]
    result = FinancialStrategyLibraryPanelV1.PanelStrategy[]
    for security in origin.selected,
        signal in String.(grammar["directional_signal"]),
        filter in String.(grammar["entry_filter"]),
        horizon in Int.(grammar["holding_horizon"]),
        sizing in String.(grammar["sizing_rule"]),
        exit_rule in String.(grammar["exit_rule"]),
        risk in String.(grammar["risk_constraint"])
        push!(result, _strategy(
            origin.origin_id,
            security.permno,
            signal,
            filter,
            horizon,
            sizing,
            exit_rule,
            risk,
        ))
    end
    sort!(result; by = _strategy_key)
    length(result) == length(origin.selected) * Int(grammar["strategies_per_instrument"]) ||
        error("v2 grammar catalog size mismatch")
    return result
end

function _utility(values, annualization::Int, risk_aversion::Int)
    isempty(values) && return NaN
    mean_value = sum(values) / length(values)
    variance = length(values) <= 1 ? 0.0 :
        sum(value -> (value - mean_value)^2, values) / (length(values) - 1)
    return annualization * mean_value -
           0.5 * risk_aversion * annualization * variance
end

function _source_schema_audit(config, metadata)
    security_required = String.(config["source"]["required_security_history_columns"]["columns"])
    amended_market_required = collect(REQUIRED_MARKET_HISTORY_COLUMNS)
    daily_required = String.(config["source"]["required_daily_columns"]["columns"])
    schemas = Dict{String,Any}()
    open(metadata.paths.security_history, "r") do io
        header = strip.(FinancialStrategyLibraryPanelV1._split_csv(chomp(readline(io))))
        FinancialStrategyLibraryPanelV1._positions(header, security_required)
        FinancialStrategyLibraryPanelV1._positions(header, amended_market_required)
        schemas["security_history"] = header
    end
    for (index, path) in enumerate(metadata.paths.daily_files)
        FinancialStrategyLibraryPanelV1._with_daily_file(path) do io
            header = strip.(FinancialStrategyLibraryPanelV1._split_csv(chomp(readline(io))))
            FinancialStrategyLibraryPanelV1._positions(header, daily_required)
            schemas["daily_$index"] = header
            for _ in eachline(io)
                nothing
            end
        end
    end
    payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v2-source-audit-v1",
        "recorded_at_utc" => _utc_now(),
        "required_schema_passed" => true,
        "amended_market_history_columns" => amended_market_required,
        "source_files" => [Dict{String,Any}(
            "role" => item.relative_role,
            "byte_size" => item.byte_size,
            "modified_unix_seconds" => item.modified_unix_seconds,
            "sha256" => _sha256_file(item.path),
        ) for item in metadata.files],
        "observed_columns" => schemas,
        "licensed_rows_included" => false,
    )
    _atomic_toml(joinpath(LOCAL_RESULTS_ROOT, "SOURCE_AUDIT.toml"), payload)
    return payload
end

function _decision_dates_parallel(daily_files, origins, reference_permnos, config)
    Threads.nthreads() > 1 || error("parallel decision scan requires multiple Julia threads")
    targets = Dict(origin.origin_id => "$(origin.decision_year)-12-31" for origin in origins)
    origin_by_permno = Dict{Int,Vector{NamedTuple}}()
    for origin in origins
        push!(get!(origin_by_permno, reference_permnos[origin.origin_id], NamedTuple[]), (;
            origin_id = origin.origin_id,
            year = origin.decision_year,
        ))
    end
    required = String.(config["source"]["required_daily_columns"]["columns"])
    partial = [Dict(origin.origin_id => "" for origin in origins) for _ in daily_files]
    errors = Vector{Union{Nothing,String}}(undef, length(daily_files))
    fill!(errors, nothing)
    Threads.@threads :static for file_index in eachindex(daily_files)
        try
            _progress("parallel decision scan started file $file_index/$(length(daily_files))")
            FinancialStrategyLibraryPanelV1._with_daily_file(daily_files[file_index]) do io
                header = strip.(FinancialStrategyLibraryPanelV1._split_csv(chomp(readline(io))))
                positions = FinancialStrategyLibraryPanelV1._positions(header, required)
                rows = 0
                for line in eachline(io)
                    rows += 1
                    fields = FinancialStrategyLibraryPanelV1._split_csv(chomp(line))
                    permno = tryparse(Int, strip(fields[positions["permno"]]))
                    isnothing(permno) && continue
                    candidate_origins = get(origin_by_permno, permno, NamedTuple[])
                    isempty(candidate_origins) && continue
                    date = strip(fields[positions["dlycaldt"]])
                    for origin in candidate_origins
                        startswith(date, "$(origin.year)-") || continue
                        date <= targets[origin.origin_id] || continue
                        partial[file_index][origin.origin_id] = max(
                            partial[file_index][origin.origin_id],
                            date,
                        )
                    end
                end
                _progress("parallel decision scan completed file $file_index/$(length(daily_files)) rows=$rows")
            end
        catch exception
            errors[file_index] = sprint(showerror, exception)
        end
    end
    failed = findall(!isnothing, errors)
    isempty(failed) || error(join(("file $index: $(errors[index])" for index in failed), "; "))
    result = Dict{String,String}()
    for origin in origins
        result[origin.origin_id] = maximum(part[origin.origin_id] for part in partial)
        isempty(result[origin.origin_id]) && error("registered origin has no SPY decision session")
    end
    return result
end

function _liquidity_stats_parallel(daily_files, memberships, stats, config)
    required = String.(config["source"]["required_daily_columns"]["columns"])
    partial = [Dict{Tuple{String,Int},FinancialStrategyLibraryPanelV1.UniverseStats}() for _ in daily_files]
    errors = Vector{Union{Nothing,String}}(undef, length(daily_files))
    fill!(errors, nothing)
    Threads.@threads :static for file_index in eachindex(daily_files)
        try
            _progress("parallel liquidity scan started file $file_index/$(length(daily_files))")
            last_date = Dict{Int,String}()
            rows = 0
            FinancialStrategyLibraryPanelV1._with_daily_file(daily_files[file_index]) do io
                header = strip.(FinancialStrategyLibraryPanelV1._split_csv(chomp(readline(io))))
                positions = FinancialStrategyLibraryPanelV1._positions(header, required)
                for line in eachline(io)
                    rows += 1
                    fields = FinancialStrategyLibraryPanelV1._split_csv(chomp(line))
                    length(fields) == length(header) || error("daily-security CSV width mismatch")
                    permno = tryparse(Int, strip(fields[positions["permno"]]))
                    isnothing(permno) && continue
                    candidates = get(memberships, permno, NamedTuple[])
                    isempty(candidates) && continue
                    date = strip(fields[positions["dlycaldt"]])
                    date > get(last_date, permno, "") || error("duplicate or unstable file-local candidate ordering")
                    last_date[permno] = date
                    for membership in candidates
                        date <= membership.decision || continue
                        key = (membership.origin_id, permno)
                        entry = get!(partial[file_index], key, FinancialStrategyLibraryPanelV1.UniverseStats())
                        entry.daily_rows += 1
                        membership.compression_start <= date || continue
                        entry.compression_rows += 1
                        close = FinancialStrategyLibraryPanelV1._positive_close(fields, positions)
                        volume = FinancialStrategyLibraryPanelV1._parse_float(fields[positions["dlyvol"]])
                        if isnothing(close) || isnothing(volume) || volume < 0
                            entry.invalid_liquidity_rows += 1
                        else
                            push!(entry.closes, close)
                            push!(entry.dollar_volumes, close * volume)
                        end
                    end
                end
            end
            _progress("parallel liquidity scan completed file $file_index/$(length(daily_files)) rows=$rows")
        catch exception
            errors[file_index] = sprint(showerror, exception)
        end
    end
    failed = findall(!isnothing, errors)
    isempty(failed) || error(join(("file $index: $(errors[index])" for index in failed), "; "))
    for file_index in eachindex(partial), (key, file_entry) in partial[file_index]
        entry = stats[key]
        entry.daily_rows += file_entry.daily_rows
        entry.compression_rows += file_entry.compression_rows
        entry.invalid_liquidity_rows += file_entry.invalid_liquidity_rows
        append!(entry.closes, file_entry.closes)
        append!(entry.dollar_volumes, file_entry.dollar_volumes)
    end
    return stats
end

function _provisional_universes(config, paths)
    intervals = FinancialStrategyLibraryPanelV1._load_security_intervals(
        paths.security_history,
        config,
    )
    origins = FinancialStrategyLibraryPanelV2Registries.origin_rows()
    reference_permnos = FinancialStrategyLibraryPanelV1._reference_permnos(
        intervals,
        origins,
        config,
    )
    decisions = _decision_dates_parallel(
        paths.daily_files,
        origins,
        reference_permnos,
        config,
    )
    interval_maps = Dict(
        origin.origin_id => FinancialStrategyLibraryPanelV1._origin_interval_rows(
            intervals,
            decisions[origin.origin_id],
            config,
        ) for origin in origins
    )
    memberships = Dict{Int,Vector{NamedTuple}}()
    stats = Dict{Tuple{String,Int},FinancialStrategyLibraryPanelV1.UniverseStats}()
    for origin in origins
        compression_start = "$(origin.compression_start_year)-01-01"
        decision = decisions[origin.origin_id]
        for permno in keys(interval_maps[origin.origin_id])
            push!(get!(memberships, permno, NamedTuple[]), (;
                origin_id = origin.origin_id,
                compression_start,
                decision,
            ))
            stats[(origin.origin_id, permno)] = FinancialStrategyLibraryPanelV1.UniverseStats()
        end
    end
    _liquidity_stats_parallel(paths.daily_files, memberships, stats, config)
    universe = config["universe"]
    keywords = uppercase.(String.(universe["exclude_name_keywords"]))
    candidates = Dict{String,Vector{NamedTuple}}()
    exclusions = Dict{String,Vector{Dict{String,Any}}}()
    for origin in origins
        eligible = NamedTuple[]
        excluded = Dict{String,Any}[]
        for (permno, interval) in interval_maps[origin.origin_id]
            entry = stats[(origin.origin_id, permno)]
            median_close = FinancialStrategyLibraryPanelV1._median(entry.closes)
            median_dollar_volume = FinancialStrategyLibraryPanelV1._median(entry.dollar_volumes)
            name = uppercase(interval.security_name)
            reasons = String[]
            entry.daily_rows < Int(universe["minimum_preorigin_daily_observations"]) &&
                push!(reasons, "insufficient_preorigin_daily_rows")
            length(entry.dollar_volumes) < Int(universe["minimum_compression_window_liquidity_observations"]) &&
                push!(reasons, "insufficient_compression_liquidity_rows")
            (!isfinite(median_close) || median_close < Float64(universe["minimum_median_close"])) &&
                push!(reasons, "price_floor")
            (!isfinite(median_dollar_volume) || median_dollar_volume < Float64(universe["minimum_median_dollar_volume"])) &&
                push!(reasons, "dollar_volume_floor")
            any(keyword -> occursin(keyword, name), keywords) &&
                push!(reasons, "complex_product_keyword")
            if isempty(reasons)
                push!(eligible, (;
                    permno,
                    ticker = interval.ticker,
                    security_name_sha256 = _sha256_text(interval.security_name),
                    median_close,
                    median_dollar_volume,
                    preorigin_daily_rows = entry.daily_rows,
                    compression_liquidity_rows = length(entry.dollar_volumes),
                    invalid_liquidity_rows = entry.invalid_liquidity_rows,
                ))
            else
                push!(excluded, Dict{String,Any}(
                    "permno" => permno,
                    "reasons" => reasons,
                ))
            end
        end
        sort!(eligible; by = row -> (-row.median_dollar_volume, row.permno))
        candidates[origin.origin_id] = eligible
        exclusions[origin.origin_id] = excluded
    end
    return (; origins, decisions, reference_permnos, candidates, exclusions)
end

function _origin_market_interval_rows(intervals, date)
    by_permno = Dict{Int,V2MarketInterval}()
    for interval in intervals
        interval.start_date <= date <= interval.end_date || continue
        isempty(_instrument_class(interval)) && continue
        haskey(by_permno, interval.permno) && error(
            "overlapping origin-valid market-history rows for one PERMNO",
        )
        by_permno[interval.permno] = interval
    end
    return by_permno
end

function _market_reference_permnos(intervals, origins)
    result = Dict{String,Int}()
    for origin in origins
        provisional_date = "$(origin.decision_year)-12-31"
        matches = [
            interval for interval in intervals if
            interval.start_date <= provisional_date <= interval.end_date &&
            interval.ticker == "SPY" && _instrument_class(interval) == "plain_etf"
        ]
        length(matches) == 1 || error(
            "expected one origin-valid SPY interval for $(origin.origin_id)",
        )
        result[origin.origin_id] = only(matches).permno
    end
    return result
end

function _master_decision_dates(chunks, origins, reference_permnos)
    targets = Dict(origin.origin_id => "$(origin.decision_year)-12-31" for origin in origins)
    dates = Dict(origin.origin_id => "" for origin in origins)
    memberships = Dict{Int,Vector{NamedTuple}}()
    for origin in origins
        push!(get!(memberships, reference_permnos[origin.origin_id], NamedTuple[]), (;
            origin_id = origin.origin_id,
            year_prefix = "$(origin.decision_year)-",
        ))
    end
    for (chunk_index, path) in enumerate(chunks)
        columns = FinancialStrategyLibraryPanelV1.parquet_columns(path; use_threads = false)
        for index in eachindex(columns.permno)
            permno = Int(columns.permno[index])
            candidates = get(memberships, permno, NamedTuple[])
            isempty(candidates) && continue
            date = String(columns.date[index])
            for candidate in candidates
                startswith(date, candidate.year_prefix) || continue
                date <= targets[candidate.origin_id] || continue
                dates[candidate.origin_id] = max(dates[candidate.origin_id], date)
            end
        end
        chunk_index % 25 == 0 && _progress(
            "master-panel decision scan completed chunk $chunk_index/$(length(chunks))",
        )
    end
    all(!isempty, values(dates)) || error("a registered origin has no SPY decision session")
    return dates
end

function _provisional_universes_master(config, chunks, intervals)
    origins = FinancialStrategyLibraryPanelV2Registries.origin_rows()
    reference_permnos = _market_reference_permnos(intervals, origins)
    decisions = _master_decision_dates(chunks, origins, reference_permnos)
    interval_maps = Dict(
        origin.origin_id => _origin_market_interval_rows(
            intervals,
            decisions[origin.origin_id],
        ) for origin in origins
    )
    memberships = Dict{Int,Vector{NamedTuple}}()
    stats = Dict{Tuple{String,Int},FinancialStrategyLibraryPanelV1.UniverseStats}()
    for origin in origins
        origin_id = origin.origin_id
        compression_start = "$(origin.compression_start_year)-01-01"
        decision = decisions[origin_id]
        for permno in keys(interval_maps[origin_id])
            push!(get!(memberships, permno, NamedTuple[]), (;
                origin_id,
                compression_start,
                decision,
            ))
            stats[(origin_id, permno)] = FinancialStrategyLibraryPanelV1.UniverseStats()
        end
    end
    last_date = Dict{Int,String}()
    for (chunk_index, path) in enumerate(chunks)
        columns = FinancialStrategyLibraryPanelV1.parquet_columns(path; use_threads = false)
        for index in eachindex(columns.permno)
            permno = Int(columns.permno[index])
            date = String(columns.date[index])
            date > get(last_date, permno, "") ||
                error("duplicate or unstable cross-chunk master-panel ordering")
            last_date[permno] = date
            candidate_memberships = get(memberships, permno, NamedTuple[])
            isempty(candidate_memberships) && continue
            close = columns.close[index]
            volume = columns.volume[index]
            for membership in candidate_memberships
                date <= membership.decision || continue
                entry = stats[(membership.origin_id, permno)]
                entry.daily_rows += 1
                membership.compression_start <= date || continue
                entry.compression_rows += 1
                if ismissing(close) || ismissing(volume) || volume < 0
                    entry.invalid_liquidity_rows += 1
                else
                    push!(entry.closes, Float64(close))
                    push!(entry.dollar_volumes, Float64(close) * Float64(volume))
                end
            end
        end
        chunk_index % 25 == 0 && _progress(
            "master-panel liquidity scan completed chunk $chunk_index/$(length(chunks))",
        )
    end
    universe = config["universe"]
    keywords = uppercase.(String.(universe["exclude_name_keywords"]))
    candidates = Dict{String,Vector{NamedTuple}}()
    exclusions = Dict{String,Vector{Dict{String,Any}}}()
    for origin in origins
        origin_id = origin.origin_id
        eligible = NamedTuple[]
        excluded = Dict{String,Any}[]
        for (permno, interval) in interval_maps[origin_id]
            entry = stats[(origin_id, permno)]
            median_close = FinancialStrategyLibraryPanelV1._median(entry.closes)
            median_dollar_volume = FinancialStrategyLibraryPanelV1._median(entry.dollar_volumes)
            instrument_class = _instrument_class(interval)
            reasons = String[]
            entry.daily_rows < Int(universe["minimum_preorigin_daily_observations"]) &&
                push!(reasons, "insufficient_preorigin_daily_rows")
            length(entry.dollar_volumes) < Int(universe["minimum_compression_window_liquidity_observations"]) &&
                push!(reasons, "insufficient_compression_liquidity_rows")
            (!isfinite(median_close) || median_close < Float64(universe["minimum_median_close"])) &&
                push!(reasons, "price_floor")
            (!isfinite(median_dollar_volume) || median_dollar_volume < Float64(universe["minimum_median_dollar_volume"])) &&
                push!(reasons, "dollar_volume_floor")
            instrument_class == "plain_etf" &&
                any(keyword -> occursin(keyword, uppercase(interval.security_name)), keywords) &&
                push!(reasons, "complex_product_keyword")
            if isempty(reasons)
                push!(eligible, (;
                    permno,
                    ticker = interval.ticker,
                    instrument_class,
                    security_name_sha256 = _sha256_text(interval.security_name),
                    median_close,
                    median_dollar_volume,
                    preorigin_daily_rows = entry.daily_rows,
                    compression_liquidity_rows = length(entry.dollar_volumes),
                    invalid_liquidity_rows = entry.invalid_liquidity_rows,
                ))
            else
                push!(excluded, Dict{String,Any}(
                    "permno" => permno,
                    "instrument_class" => instrument_class,
                    "reasons" => reasons,
                ))
            end
        end
        sort!(eligible; by = row -> (-row.median_dollar_volume, row.permno))
        candidates[origin_id] = eligible
        exclusions[origin_id] = excluded
    end
    return (; origins, decisions, reference_permnos, candidates, exclusions)
end

function _origin_shell(origin, decision, reference_permno; selected = NamedTuple[])
    return FinancialStrategyLibraryPanelV1.OriginUniverse(
        origin.origin_id,
        origin.decision_year,
        decision,
        "$(origin.construction_start_year)-01-01",
        "$(origin.construction_end_year)-12-31",
        "$(origin.compression_start_year)-01-01",
        decision,
        "$(origin.postdecision_year)-01-01",
        "$(origin.postdecision_year)-12-31",
        collect(selected),
        length(selected),
        length(selected),
        reference_permno,
    )
end

_known_missing_return_flag(flag::AbstractString) =
    String(flag) in KNOWN_CRSP_MISSING_RETURN_FLAGS

function _stage_panel_partitions(
    config,
    daily_files,
    origins,
    execution_lock_aggregate;
    phase::Symbol,
    cache_root::AbstractString,
)
    phase in (:structural, :postdecision) ||
        throw(ArgumentError("panel phase must be structural or postdecision"))
    isempty(origins) && return String[]
    Threads.nthreads() > 1 || error("parallel panel staging requires multiple Julia threads")
    contexts, _, _ = FinancialStrategyLibraryPanelV1._origin_series_contexts(origins, phase)
    required = String.(config["source"]["required_daily_columns"]["columns"])
    partitions = Vector{String}(undef, length(daily_files))
    errors = Vector{Union{Nothing,String}}(undef, length(daily_files))
    fill!(errors, nothing)
    Threads.@threads :static for file_index in eachindex(daily_files)
        try
            stem = "$(String(phase))-source-$(lpad(file_index, 3, '0'))"
            parquet_path = joinpath(cache_root, stem * ".parquet")
            metadata_path = joinpath(cache_root, stem * ".toml")
            !ispath(parquet_path) && !ispath(metadata_path) ||
                error("immutable staged-panel partition already exists")
            origin_column = String[]
            permno_column = Int64[]
            date_column = String[]
            return_column = Union{Missing,Float64}[]
            close_column = Union{Missing,Float64}[]
            volume_column = Union{Missing,Float64}[]
            delisting_flag_column = String[]
            return_flag_column = String[]
            source_row_index_column = Int64[]
            source_rows_scanned = 0
            _progress("parallel $phase panel staging started file $file_index/$(length(daily_files))")
            FinancialStrategyLibraryPanelV1._with_daily_file(daily_files[file_index]) do io
                header = strip.(FinancialStrategyLibraryPanelV1._split_csv(chomp(readline(io))))
                positions = FinancialStrategyLibraryPanelV1._positions(header, required)
                for line in eachline(io)
                    source_rows_scanned += 1
                    source_rows_scanned % 5_000_000 == 0 && _progress(
                        "parallel $phase panel staging file $file_index rows=$source_rows_scanned",
                    )
                    fields = FinancialStrategyLibraryPanelV1._split_csv(chomp(line))
                    length(fields) == length(header) || error("daily-security CSV width mismatch")
                    permno = tryparse(Int, strip(fields[positions["permno"]]))
                    isnothing(permno) && continue
                    candidate_contexts = get(contexts, permno, NamedTuple[])
                    isempty(candidate_contexts) && continue
                    date = strip(fields[positions["dlycaldt"]])
                    matching = [
                        context for context in candidate_contexts if
                        context.window_start <= date <= context.window_end
                    ]
                    isempty(matching) && continue
                    total_return = FinancialStrategyLibraryPanelV1._parse_float(
                        fields[positions["dlyret"]],
                    )
                    return_flag = strip(fields[positions["dlyretmissflg"]])
                    if isnothing(total_return)
                        _known_missing_return_flag(return_flag) || error(
                            "staged panel found an unknown or contradictory missing-return flag",
                        )
                    else
                        total_return > -1 || error("staged panel found an uncompoundable return")
                        return_flag == "NA" || error(
                            "staged panel found a finite return without CRSP flag NA",
                        )
                    end
                    close = FinancialStrategyLibraryPanelV1._positive_close(fields, positions)
                    volume = FinancialStrategyLibraryPanelV1._parse_float(fields[positions["dlyvol"]])
                    invalid_volume = isnothing(volume) || volume < 0
                    delisting_flag = strip(fields[positions["dlydelflg"]])
                    for context in matching
                        push!(origin_column, context.origin_id)
                        push!(permno_column, Int64(permno))
                        push!(date_column, date)
                        push!(return_column, isnothing(total_return) ? missing : total_return)
                        push!(close_column, isnothing(close) ? missing : close)
                        push!(volume_column, invalid_volume ? missing : volume)
                        push!(delisting_flag_column, delisting_flag)
                        push!(return_flag_column, return_flag)
                        push!(source_row_index_column, Int64(source_rows_scanned))
                    end
                end
            end
            columns = (
                origin_id = origin_column,
                permno = permno_column,
                date = date_column,
                total_return = return_column,
                close = close_column,
                volume = volume_column,
                delisting_flag = delisting_flag_column,
                return_flag = return_flag_column,
                source_row_index = source_row_index_column,
            )
            FinancialStrategyLibraryPanelV1.atomic_write_parquet(
                parquet_path,
                columns;
                replace = false,
            )
            _atomic_toml(metadata_path, Dict{String,Any}(
                "schema_version" => "financial-panel-v2-staged-panel-v1",
                "phase" => String(phase),
                "source_file_index" => file_index,
                "source_file_count" => length(daily_files),
                "source_file_basename" => basename(daily_files[file_index]),
                "source_byte_size" => filesize(daily_files[file_index]),
                "source_modified_unix_seconds" => round(Int, stat(daily_files[file_index]).mtime),
                "source_rows_scanned" => source_rows_scanned,
                "retained_origin_rows" => length(origin_column),
                "parquet_sha256" => _sha256_file(parquet_path),
                "execution_lock_aggregate_sha256" => execution_lock_aggregate,
                "local_licensed_rows_included" => true,
                "public_promotion_permitted" => false,
            ))
            partitions[file_index] = parquet_path
            _progress(
                "parallel $phase panel staging completed file $file_index/$(length(daily_files)) " *
                "source_rows=$source_rows_scanned retained_origin_rows=$(length(origin_column))",
            )
        catch exception
            errors[file_index] = sprint(showerror, exception)
        end
    end
    failed = findall(!isnothing, errors)
    isempty(failed) || error(join(("file $index: $(errors[index])" for index in failed), "; "))
    return partitions
end

function _load_staged_panel(partitions, origins; phase::Symbol)
    selected_by_origin = Dict(
        origin.origin_id => sort!(unique([
            origin.reference_permno;
            Int[row.permno for row in origin.selected]
        ])) for origin in origins
    )
    panel = Dict(
        origin_id => Dict(permno => NamedTuple[] for permno in selected)
        for (origin_id, selected) in selected_by_origin
    )
    quality = Dict(
        origin_id => Dict(
            "origin_security_series" => length(selected),
            "source_rows_seen" => 0,
            "valid_return_rows" => 0,
            "known_missing_return_rows" => 0,
            "invalid_close_rows" => 0,
            "invalid_volume_rows" => 0,
        ) for (origin_id, selected) in selected_by_origin
    )
    last_date = Dict{Tuple{String,Int},String}()
    expected_columns = (
        :origin_id,
        :permno,
        :date,
        :total_return,
        :close,
        :volume,
        :delisting_flag,
        :return_flag,
        :source_row_index,
    )
    for path in partitions
        columns = FinancialStrategyLibraryPanelV1.parquet_columns(path; use_threads = false)
        propertynames(columns) == expected_columns || error("staged-panel schema changed")
        for index in eachindex(columns.origin_id)
            origin_id = String(columns.origin_id[index])
            permno = Int(columns.permno[index])
            date = String(columns.date[index])
            key = (origin_id, permno)
            date > get(last_date, key, "") ||
                error("duplicate or unstable staged-panel origin-security date order")
            last_date[key] = date
            total_return = columns.total_return[index]
            close = columns.close[index]
            volume = columns.volume[index]
            return_flag = String(columns.return_flag[index])
            row = (
                date,
                total_return = ismissing(total_return) ? missing : Float64(total_return),
                close = ismissing(close) ? missing : Float64(close),
                volume = ismissing(volume) ? missing : Float64(volume),
                delisting_flag = String(columns.delisting_flag[index]),
                return_flag,
            )
            push!(panel[origin_id][permno], row)
            counts = quality[origin_id]
            counts["source_rows_seen"] += 1
            if ismissing(row.total_return)
                _known_missing_return_flag(return_flag) ||
                    error("unknown missing-return flag survived panel staging")
                counts["known_missing_return_rows"] += 1
            else
                return_flag == "NA" || error("finite staged return lost flag NA")
                counts["valid_return_rows"] += 1
            end
            ismissing(row.close) && (counts["invalid_close_rows"] += 1)
            ismissing(row.volume) && (counts["invalid_volume_rows"] += 1)
        end
    end
    for (origin_id, counts) in quality
        counts["source_rows_seen"] ==
        counts["valid_return_rows"] + counts["known_missing_return_rows"] ||
            error("staged-panel quality counts do not reconcile: $origin_id")
    end
    return panel, quality
end

function _reference_states_from_panel(config, provisional, panel)
    thresholds = Dict{String,Vector{Float64}}()
    states = Dict{String,Dict{String,Int}}()
    runtime = _runtime_config(config)
    amendment = _runtime_amendment()
    for origin in provisional.origins
        shell = _origin_shell(
            origin,
            provisional.decisions[origin.origin_id],
            provisional.reference_permnos[origin.origin_id],
        )
        rows = panel[origin.origin_id][shell.reference_permno]
        all(row -> !ismissing(row.total_return) && !ismissing(row.close) && !ismissing(row.volume), rows) ||
            error("SPY is incomplete in a registered predecision staging window")
        observations = FinancialStrategyLibraryPanelV1.DailyObservation[
            FinancialStrategyLibraryPanelV1.DailyObservation(
                row.date,
                row.total_return,
                row.close,
                row.volume,
                row.delisting_flag,
                row.return_flag,
            ) for row in rows
        ]
        threshold, state_by_date = FinancialStrategyLibraryPanelV1._belief_states(
            shell,
            observations,
            runtime,
            amendment,
        )
        thresholds[origin.origin_id] = threshold
        states[origin.origin_id] = state_by_date
    end
    return thresholds, states
end

function _reference_states_master(config, provisional, chunks)
    contexts = Dict{Int,Vector{NamedTuple}}()
    observations = Dict(
        origin.origin_id => FinancialStrategyLibraryPanelV1.DailyObservation[]
        for origin in provisional.origins
    )
    for origin in provisional.origins
        origin_id = origin.origin_id
        push!(get!(contexts, provisional.reference_permnos[origin_id], NamedTuple[]), (;
            origin_id,
            window_start = "$(origin.construction_start_year - 1)-01-01",
            window_end = provisional.decisions[origin_id],
        ))
    end
    last_date = Dict{Tuple{String,Int},String}()
    for (chunk_index, path) in enumerate(chunks)
        columns = FinancialStrategyLibraryPanelV1.parquet_columns(path; use_threads = false)
        for index in eachindex(columns.permno)
            permno = Int(columns.permno[index])
            candidate_contexts = get(contexts, permno, NamedTuple[])
            isempty(candidate_contexts) && continue
            date = String(columns.date[index])
            for context in candidate_contexts
                context.window_start <= date <= context.window_end || continue
                key = (context.origin_id, permno)
                date > get(last_date, key, "") || error("SPY reference dates are not unique and ordered")
                last_date[key] = date
                total_return = columns.total_return[index]
                close = columns.close[index]
                volume = columns.volume[index]
                (!ismissing(total_return) && String(columns.return_flag[index]) == "NA" &&
                 !ismissing(close) && !ismissing(volume)) ||
                    error("SPY is incomplete in a registered predecision reference window")
                push!(observations[context.origin_id], FinancialStrategyLibraryPanelV1.DailyObservation(
                    date,
                    Float64(total_return),
                    Float64(close),
                    Float64(volume),
                    String(columns.delisting_flag[index]),
                    String(columns.return_flag[index]),
                ))
            end
        end
        chunk_index % 25 == 0 && _progress(
            "master-panel SPY-state scan completed chunk $chunk_index/$(length(chunks))",
        )
    end
    thresholds = Dict{String,Vector{Float64}}()
    states = Dict{String,Dict{String,Int}}()
    calendars = Dict{String,Vector{String}}()
    runtime = _runtime_config(config)
    amendment = _runtime_amendment()
    for origin in provisional.origins
        origin_id = origin.origin_id
        shell = _origin_shell(
            origin,
            provisional.decisions[origin_id],
            provisional.reference_permnos[origin_id],
        )
        threshold, state_by_date = FinancialStrategyLibraryPanelV1._belief_states(
            shell,
            observations[origin_id],
            runtime,
            amendment,
        )
        thresholds[origin_id] = threshold
        states[origin_id] = state_by_date
        calendars[origin_id] = getfield.(observations[origin_id], :date)
    end
    return thresholds, states, calendars
end

function _complete_case_universes_master(
    config,
    provisional,
    chunks,
    states,
    calendars,
    thresholds,
)
    contexts = Dict{Int,Vector{NamedTuple}}()
    stats = Dict{Tuple{String,Int},CompleteCaseStats}()
    calendar_sets = Dict(origin_id => Set(dates) for (origin_id, dates) in calendars)
    for origin in provisional.origins
        origin_id = origin.origin_id
        for candidate in provisional.candidates[origin_id]
            push!(get!(contexts, candidate.permno, NamedTuple[]), (;
                origin_id,
                window_start = "$(origin.construction_start_year - 1)-01-01",
                construction_start = "$(origin.construction_start_year)-01-01",
                construction_end = "$(origin.construction_end_year)-12-31",
                compression_start = "$(origin.compression_start_year)-01-01",
                window_end = provisional.decisions[origin_id],
            ))
            stats[(origin_id, candidate.permno)] = CompleteCaseStats()
        end
    end
    last_date = Dict{Int,String}()
    for (chunk_index, path) in enumerate(chunks)
        columns = FinancialStrategyLibraryPanelV1.parquet_columns(path; use_threads = false)
        for index in eachindex(columns.permno)
            permno = Int(columns.permno[index])
            date = String(columns.date[index])
            date > get(last_date, permno, "") ||
                error("duplicate or unstable master-panel ordering during complete-case scan")
            last_date[permno] = date
            candidate_contexts = get(contexts, permno, NamedTuple[])
            isempty(candidate_contexts) && continue
            for context in candidate_contexts
                context.window_start <= date <= context.window_end || continue
                entry = stats[(context.origin_id, permno)]
                if !(date in calendar_sets[context.origin_id])
                    entry.nonreference_sessions += 1
                    continue
                end
                entry.observed_reference_sessions += 1
                total_return = columns.total_return[index]
                close = columns.close[index]
                volume = columns.volume[index]
                (ismissing(total_return) || String(columns.return_flag[index]) != "NA") &&
                    (entry.missing_return_sessions += 1)
                ismissing(close) && (entry.invalid_price_sessions += 1)
                ismissing(volume) && (entry.invalid_volume_sessions += 1)
                if ismissing(total_return) || String(columns.return_flag[index]) != "NA" ||
                   ismissing(close) || ismissing(volume)
                    continue
                end
                state = get(states[context.origin_id], date, 0)
                iszero(state) && continue
                context.construction_start <= date <= context.construction_end &&
                    (entry.construction_profile_counts[state] += 1)
                context.compression_start <= date <= context.window_end &&
                    (entry.compression_profile_counts[state] += 1)
            end
        end
        chunk_index % 25 == 0 && _progress(
            "master-panel complete-case scan completed chunk $chunk_index/$(length(chunks))",
        )
    end
    minimum = Int(config["universe"]["minimum_construction_observations_per_belief"])
    hard_profile_gate = Bool(config["universe"]["profile_support_is_security_eligibility_rule"])
    minimum_origin = Int(config["universe"]["minimum_eligible_for_origin"])
    cap = Int(config["universe"]["maximum_eligible_by_liquidity"])
    evaluable = FinancialStrategyLibraryPanelV1.OriginUniverse[]
    status = Dict{String,Dict{String,Any}}()
    for origin in provisional.origins
        origin_id = origin.origin_id
        complete = NamedTuple[]
        complete_exclusions = Dict{String,Any}[]
        expected_sessions = length(calendars[origin_id])
        for candidate in provisional.candidates[origin_id]
            entry = stats[(origin_id, candidate.permno)]
            absent_sessions = expected_sessions - entry.observed_reference_sessions
            absent_sessions >= 0 || error("security has more reference sessions than SPY")
            complete_calendar = absent_sessions == 0 && entry.missing_return_sessions == 0 &&
                entry.invalid_price_sessions == 0 && entry.invalid_volume_sessions == 0
            profile_complete = all(>=(minimum), entry.construction_profile_counts) &&
                all(>=(minimum), entry.compression_profile_counts)
            if complete_calendar && (!hard_profile_gate || profile_complete)
                push!(complete, merge(candidate, (;
                    construction_profile_counts = entry.construction_profile_counts,
                    compression_profile_counts = entry.compression_profile_counts,
                    complete_predecision_sessions = expected_sessions,
                    unexpected_nonreference_sessions = entry.nonreference_sessions,
                )))
            else
                push!(complete_exclusions, Dict{String,Any}(
                    "permno" => candidate.permno,
                    "instrument_class" => candidate.instrument_class,
                    "reason" => complete_calendar ? "insufficient_profile_support_under_hard_gate" :
                        "incomplete_predecision_reference_calendar",
                    "expected_sessions" => expected_sessions,
                    "absent_sessions" => absent_sessions,
                    "missing_return_sessions" => entry.missing_return_sessions,
                    "invalid_price_sessions" => entry.invalid_price_sessions,
                    "invalid_volume_sessions" => entry.invalid_volume_sessions,
                    "unexpected_nonreference_sessions" => entry.nonreference_sessions,
                    "construction_counts" => entry.construction_profile_counts,
                    "compression_counts" => entry.compression_profile_counts,
                ))
            end
        end
        sort!(complete; by = row -> (-row.median_dollar_volume, row.permno))
        selected = collect(first(complete, min(cap, length(complete))))
        reference = provisional.reference_permnos[origin_id]
        reason = if length(complete) < minimum_origin
            "fewer_than_minimum_complete_predecision_securities"
        elseif !any(row -> row.permno == reference, selected)
            "SPY_not_retained_after_complete_case_and_liquidity_rules"
        else
            ""
        end
        class_counts = Dict(
            class => count(row -> row.instrument_class == class, selected)
            for class in ("common_equity", "plain_etf")
        )
        payload = Dict{String,Any}(
            "schema_version" => "financial-strategy-library-panel-v2-origin-status-v3",
            "origin_id" => origin_id,
            "decision_year" => origin.decision_year,
            "decision_date" => provisional.decisions[origin_id],
            "terminal" => true,
            "structurally_evaluable" => isempty(reason),
            "reason" => reason,
            "history_interval_candidate_count" => length(provisional.candidates[origin_id]) +
                length(provisional.exclusions[origin_id]),
            "liquidity_eligible_count" => length(provisional.candidates[origin_id]),
            "complete_predecision_count" => length(complete),
            "hard_profile_support_eligibility_gate" => hard_profile_gate,
            "regime_profile_estimator" => get(
                config["operating_profiles"],
                "regime_profile_estimator",
                "unshrunk_state_cell_utility",
            ),
            "selected_security_count" => length(selected),
            "selected_instrument_class_counts" => class_counts,
            "reference_permno" => reference,
            "belief_thresholds" => thresholds[origin_id],
            "precomplete_exclusions" => provisional.exclusions[origin_id],
            "complete_case_exclusions" => complete_exclusions,
            "selected" => [Dict{String,Any}(
                "permno" => candidate.permno,
                "ticker" => candidate.ticker,
                "instrument_class" => candidate.instrument_class,
                "security_name_sha256" => candidate.security_name_sha256,
                "median_close" => candidate.median_close,
                "median_dollar_volume" => candidate.median_dollar_volume,
                "preorigin_daily_rows" => candidate.preorigin_daily_rows,
                "compression_liquidity_rows" => candidate.compression_liquidity_rows,
                "complete_predecision_sessions" => candidate.complete_predecision_sessions,
                "unexpected_nonreference_sessions" => candidate.unexpected_nonreference_sessions,
                "construction_profile_counts" => candidate.construction_profile_counts,
                "compression_profile_counts" => candidate.compression_profile_counts,
            ) for candidate in selected],
            "licensed_rows_included" => false,
        )
        status[origin_id] = payload
        _atomic_toml(joinpath(LOCAL_DATA_ROOT, "origin_status", "$origin_id.toml"), payload)
        isempty(reason) || continue
        push!(evaluable, FinancialStrategyLibraryPanelV1.OriginUniverse(
            origin_id,
            origin.decision_year,
            provisional.decisions[origin_id],
            "$(origin.construction_start_year)-01-01",
            "$(origin.construction_end_year)-12-31",
            "$(origin.compression_start_year)-01-01",
            provisional.decisions[origin_id],
            "$(origin.postdecision_year)-01-01",
            "$(origin.postdecision_year)-12-31",
            selected,
            length(provisional.candidates[origin_id]),
            length(complete),
            reference,
        ))
    end
    return evaluable, status
end

function _extract_master_observations(
    chunks,
    origins;
    phase::Symbol,
    calendars = Dict{String,Vector{String}}(),
    diagnostics::Union{Nothing,AbstractDict} = nothing,
)
    phase in (:structural, :postdecision) || error("invalid master-panel access phase")
    phase == :postdecision && verify_predecision_seal()
    contexts = Dict{Int,Vector{NamedTuple}}()
    observations = Dict{String,Dict{Int,Vector{FinancialStrategyLibraryPanelV1.DailyObservation}}}()
    quality = Dict{String,Dict{String,Int}}()
    calendar_sets = Dict(origin_id => Set(dates) for (origin_id, dates) in calendars)
    for origin in origins
        selected = sort!(unique([origin.reference_permno; Int[row.permno for row in origin.selected]]))
        observations[origin.origin_id] = Dict(
            permno => FinancialStrategyLibraryPanelV1.DailyObservation[] for permno in selected
        )
        quality[origin.origin_id] = Dict(
            "origin_security_series" => length(selected),
            "source_rows_seen" => 0,
            "valid_return_rows_retained" => 0,
            "known_missing_return_rows_excluded" => 0,
            "unused_close_missing_rows" => 0,
            "unused_volume_missing_rows" => 0,
        )
        window_start = phase == :structural ?
            "$(parse(Int, first(split(origin.construction_start, '-'))) - 1)-01-01" :
            "$(parse(Int, first(split(origin.postdecision_start, '-'))) - 1)-01-01"
        window_end = phase == :structural ? origin.compression_end : origin.postdecision_end
        for permno in selected
            push!(get!(contexts, permno, NamedTuple[]), (;
                origin_id = origin.origin_id,
                window_start,
                window_end,
            ))
        end
    end
    last_date = Dict{Tuple{String,Int},String}()
    for (chunk_index, path) in enumerate(chunks)
        columns = FinancialStrategyLibraryPanelV1.parquet_columns(path; use_threads = false)
        for index in eachindex(columns.permno)
            permno = Int(columns.permno[index])
            candidate_contexts = get(contexts, permno, NamedTuple[])
            isempty(candidate_contexts) && continue
            date = String(columns.date[index])
            for context in candidate_contexts
                context.window_start <= date <= context.window_end || continue
                phase == :structural && !(date in calendar_sets[context.origin_id]) && continue
                key = (context.origin_id, permno)
                date > get(last_date, key, "") ||
                    error("duplicate or unstable selected master-panel series")
                last_date[key] = date
                row = quality[context.origin_id]
                row["source_rows_seen"] += 1
                total_return = columns.total_return[index]
                if ismissing(total_return) || String(columns.return_flag[index]) != "NA"
                    row["known_missing_return_rows_excluded"] += 1
                    continue
                end
                close = columns.close[index]
                volume = columns.volume[index]
                if phase == :structural
                    (!ismissing(close) && !ismissing(volume)) || error(
                        "complete-case selected structural series became incomplete",
                    )
                else
                    ismissing(close) && (row["unused_close_missing_rows"] += 1)
                    ismissing(volume) && (row["unused_volume_missing_rows"] += 1)
                end
                push!(observations[context.origin_id][permno], FinancialStrategyLibraryPanelV1.DailyObservation(
                    date,
                    Float64(total_return),
                    ismissing(close) ? missing : Float64(close),
                    ismissing(volume) ? missing : Float64(volume),
                    String(columns.delisting_flag[index]),
                    String(columns.return_flag[index]),
                ))
                row["valid_return_rows_retained"] += 1
            end
        end
        chunk_index % 25 == 0 && _progress(
            "master-panel $phase access completed chunk $chunk_index/$(length(chunks))",
        )
    end
    all(series -> all(!isempty, values(series)), values(observations)) ||
        error("a selected security has no valid $phase observations")
    _atomic_toml(joinpath(LOCAL_RESULTS_ROOT, "MASTER_ACCESS_$(uppercase(String(phase))).toml"), Dict(
        "schema_version" => "financial-panel-v2-master-access-log-v1",
        "phase" => String(phase),
        "predecision_seal_required" => phase == :postdecision,
        "predecision_seal_verified" => phase == :postdecision,
        "chunk_count_read" => length(chunks),
        "origins" => quality,
        "licensed_rows_included" => false,
    ))
    if !isnothing(diagnostics)
        empty!(diagnostics)
        merge!(diagnostics, quality)
    end
    return observations
end

function _complete_case_universes(config, provisional, panel, states, thresholds)
    minimum = Int(config["universe"]["minimum_construction_observations_per_belief"])
    minimum_origin = Int(config["universe"]["minimum_eligible_for_origin"])
    cap = Int(config["universe"]["maximum_eligible_by_liquidity"])
    evaluable = FinancialStrategyLibraryPanelV1.OriginUniverse[]
    status = Dict{String,Dict{String,Any}}()
    for origin in provisional.origins
        origin_id = origin.origin_id
        decision = provisional.decisions[origin_id]
        construction_start = "$(origin.construction_start_year)-01-01"
        construction_end = "$(origin.construction_end_year)-12-31"
        compression_start = "$(origin.compression_start_year)-01-01"
        window_start = "$(origin.construction_start_year - 1)-01-01"
        reference = provisional.reference_permnos[origin_id]
        reference_rows = panel[origin_id][reference]
        expected_dates = sort!(String[
            row.date for row in reference_rows if
            window_start <= row.date <= decision &&
            !ismissing(row.total_return) && !ismissing(row.close) && !ismissing(row.volume)
        ])
        length(expected_dates) == length(unique(expected_dates)) ||
            error("SPY predecision calendar contains duplicate sessions")
        expected_set = Set(expected_dates)
        complete = NamedTuple[]
        exclusions = Dict{String,Any}[]
        for candidate in provisional.candidates[origin_id]
            rows = panel[origin_id][candidate.permno]
            by_date = Dict(row.date => row for row in rows)
            missing_sessions = 0
            invalid_return_sessions = 0
            invalid_price_sessions = 0
            invalid_volume_sessions = 0
            construction = zeros(Int, 5)
            compression = zeros(Int, 5)
            for date in expected_dates
                if !haskey(by_date, date)
                    missing_sessions += 1
                    continue
                end
                row = by_date[date]
                if ismissing(row.total_return)
                    invalid_return_sessions += 1
                    continue
                end
                if ismissing(row.close)
                    invalid_price_sessions += 1
                    continue
                end
                if ismissing(row.volume)
                    invalid_volume_sessions += 1
                    continue
                end
                state = get(states[origin_id], date, 0)
                iszero(state) && continue
                construction_start <= date <= construction_end && (construction[state] += 1)
                compression_start <= date <= decision && (compression[state] += 1)
            end
            unexpected_sessions = count(
                row -> window_start <= row.date <= decision && !(row.date in expected_set),
                rows,
            )
            complete_calendar = missing_sessions == 0 && invalid_return_sessions == 0 &&
                                invalid_price_sessions == 0 && invalid_volume_sessions == 0
            profile_complete = all(>=(minimum), construction) && all(>=(minimum), compression)
            if complete_calendar && profile_complete
                push!(complete, merge(candidate, (;
                    construction_profile_counts = construction,
                    compression_profile_counts = compression,
                    complete_predecision_sessions = length(expected_dates),
                    unexpected_nonreference_sessions = unexpected_sessions,
                )))
            else
                push!(exclusions, Dict{String,Any}(
                    "permno" => candidate.permno,
                    "reason" => complete_calendar ? "insufficient_profile_support" :
                        "incomplete_predecision_reference_calendar",
                    "expected_sessions" => length(expected_dates),
                    "missing_sessions" => missing_sessions,
                    "missing_return_sessions" => invalid_return_sessions,
                    "invalid_price_sessions" => invalid_price_sessions,
                    "invalid_volume_sessions" => invalid_volume_sessions,
                    "unexpected_nonreference_sessions" => unexpected_sessions,
                    "construction_counts" => construction,
                    "compression_counts" => compression,
                ))
            end
        end
        sort!(complete; by = row -> (-row.median_dollar_volume, row.permno))
        selected = collect(first(complete, min(cap, length(complete))))
        reason = if length(complete) < minimum_origin
            "fewer_than_minimum_complete_predecision_securities"
        elseif !any(row -> row.permno == reference, selected)
            "SPY_not_retained_after_complete_case_and_liquidity_rules"
        else
            ""
        end
        payload = Dict{String,Any}(
            "schema_version" => "financial-strategy-library-panel-v2-origin-status-v2",
            "origin_id" => origin_id,
            "decision_year" => origin.decision_year,
            "decision_date" => decision,
            "terminal" => true,
            "structurally_evaluable" => isempty(reason),
            "reason" => reason,
            "history_interval_candidate_count" => length(provisional.candidates[origin_id]) +
                length(provisional.exclusions[origin_id]),
            "liquidity_eligible_count" => length(provisional.candidates[origin_id]),
            "complete_predecision_count" => length(complete),
            "selected_security_count" => length(selected),
            "reference_permno" => reference,
            "belief_thresholds" => thresholds[origin_id],
            "preprofile_exclusions" => provisional.exclusions[origin_id],
            "complete_case_exclusions" => exclusions,
            "selected" => [Dict{String,Any}(
                "permno" => candidate.permno,
                "ticker" => candidate.ticker,
                "security_name_sha256" => candidate.security_name_sha256,
                "median_close" => candidate.median_close,
                "median_dollar_volume" => candidate.median_dollar_volume,
                "preorigin_daily_rows" => candidate.preorigin_daily_rows,
                "compression_liquidity_rows" => candidate.compression_liquidity_rows,
                "complete_predecision_sessions" => candidate.complete_predecision_sessions,
                "unexpected_nonreference_sessions" => candidate.unexpected_nonreference_sessions,
                "construction_profile_counts" => candidate.construction_profile_counts,
                "compression_profile_counts" => candidate.compression_profile_counts,
            ) for candidate in selected],
            "licensed_rows_included" => false,
        )
        status[origin_id] = payload
        _atomic_toml(joinpath(LOCAL_DATA_ROOT, "origin_status", "$origin_id.toml"), payload)
        isempty(reason) || continue
        push!(evaluable, FinancialStrategyLibraryPanelV1.OriginUniverse(
            origin_id,
            origin.decision_year,
            decision,
            construction_start,
            construction_end,
            compression_start,
            decision,
            "$(origin.postdecision_year)-01-01",
            "$(origin.postdecision_year)-12-31",
            selected,
            length(provisional.candidates[origin_id]),
            length(complete),
            reference,
        ))
    end
    return evaluable, status
end

function _panel_observations(panel, origins; structural::Bool)
    observations = Dict{String,Dict{Int,Vector{FinancialStrategyLibraryPanelV1.DailyObservation}}}()
    for origin in origins
        origin_rows = Dict{Int,Vector{FinancialStrategyLibraryPanelV1.DailyObservation}}()
        reference_rows = panel[origin.origin_id][origin.reference_permno]
        expected = structural ? Set(row.date for row in reference_rows if
            !ismissing(row.total_return) && !ismissing(row.close) && !ismissing(row.volume)) :
            Set{String}()
        for permno in unique([origin.reference_permno; Int[row.permno for row in origin.selected]])
            converted = FinancialStrategyLibraryPanelV1.DailyObservation[]
            for row in panel[origin.origin_id][permno]
                structural && !(row.date in expected) && continue
                ismissing(row.total_return) && continue
                structural && (ismissing(row.close) || ismissing(row.volume)) && error(
                    "complete-case structural series contains an invalid price or volume",
                )
                push!(converted, FinancialStrategyLibraryPanelV1.DailyObservation(
                    row.date,
                    row.total_return,
                    row.close,
                    row.volume,
                    row.delisting_flag,
                    row.return_flag,
                ))
            end
            isempty(converted) && error("selected security has no valid staged observations")
            origin_rows[permno] = converted
        end
        observations[origin.origin_id] = origin_rows
    end
    return observations
end

function _reference_states(config, paths, provisional, execution_lock_aggregate)
    shells = [
        _origin_shell(
            origin,
            provisional.decisions[origin.origin_id],
            provisional.reference_permnos[origin.origin_id],
        ) for origin in provisional.origins
    ]
    series = FinancialStrategyLibraryPanelV1.extract_origin_series_parquet(
        _runtime_config(config),
        paths.daily_files,
        shells;
        phase = :structural,
        cache_root = joinpath(LOCAL_DATA_ROOT, "reference_series_partitions"),
        execution_lock_aggregate,
        progress_callback = update -> _progress(
            "SPY state scan $(update.state) file $(update.file_index)/$(update.file_count) rows=$(update.source_rows_scanned)",
        ),
    )
    thresholds = Dict{String,Vector{Float64}}()
    states = Dict{String,Dict{String,Int}}()
    runtime = _runtime_config(config)
    amendment = _runtime_amendment()
    for shell in shells
        threshold, state_by_date = FinancialStrategyLibraryPanelV1._belief_states(
            shell,
            series[shell.origin_id][shell.reference_permno],
            runtime,
            amendment,
        )
        thresholds[shell.origin_id] = threshold
        states[shell.origin_id] = state_by_date
    end
    return thresholds, states
end

function _support_counts(config, paths, provisional, states)
    contexts = Dict{Int,Vector{NamedTuple}}()
    counts = Dict{Tuple{String,Int},Tuple{Vector{Int},Vector{Int}}}()
    for origin in provisional.origins
        for row in provisional.candidates[origin.origin_id]
            push!(get!(contexts, row.permno, NamedTuple[]), (;
                origin_id = origin.origin_id,
                construction_start = "$(origin.construction_start_year)-01-01",
                construction_end = "$(origin.construction_end_year)-12-31",
                compression_start = "$(origin.compression_start_year)-01-01",
                compression_end = provisional.decisions[origin.origin_id],
            ))
            counts[(origin.origin_id, row.permno)] = (zeros(Int, 5), zeros(Int, 5))
        end
    end
    required = String.(config["source"]["required_daily_columns"]["columns"])
    partial = [Dict{Tuple{String,Int},Tuple{Vector{Int},Vector{Int}}}() for _ in paths.daily_files]
    errors = Vector{Union{Nothing,String}}(undef, length(paths.daily_files))
    fill!(errors, nothing)
    Threads.@threads :static for file_index in eachindex(paths.daily_files)
        try
            _progress("parallel profile-support scan started file $file_index/$(length(paths.daily_files))")
            last_date = Dict{Int,String}()
            rows = 0
            FinancialStrategyLibraryPanelV1._with_daily_file(paths.daily_files[file_index]) do io
                header = strip.(FinancialStrategyLibraryPanelV1._split_csv(chomp(readline(io))))
                positions = FinancialStrategyLibraryPanelV1._positions(header, required)
                for line in eachline(io)
                    rows += 1
                    fields = FinancialStrategyLibraryPanelV1._split_csv(chomp(line))
                    permno = tryparse(Int, strip(fields[positions["permno"]]))
                    isnothing(permno) && continue
                    candidate_contexts = get(contexts, permno, NamedTuple[])
                    isempty(candidate_contexts) && continue
                    date = strip(fields[positions["dlycaldt"]])
                    date > get(last_date, permno, "") || error("duplicate or unstable file-local support order")
                    last_date[permno] = date
                    total_return = FinancialStrategyLibraryPanelV1._parse_float(fields[positions["dlyret"]])
                    return_flag = strip(fields[positions["dlyretmissflg"]])
                    if isnothing(total_return)
                        return_flag == "NS" && continue
                        error("profile-support scan found a non-initial missing return")
                    end
                    total_return > -1 || error("profile-support scan found an uncompoundable return")
                    for context in candidate_contexts
                        state = get(states[context.origin_id], date, 0)
                        iszero(state) && continue
                        key = (context.origin_id, permno)
                        construction, compression = get!(partial[file_index], key) do
                            (zeros(Int, 5), zeros(Int, 5))
                        end
                        context.construction_start <= date <= context.construction_end &&
                            (construction[state] += 1)
                        context.compression_start <= date <= context.compression_end &&
                            (compression[state] += 1)
                    end
                end
            end
            _progress("parallel profile-support scan completed file $file_index/$(length(paths.daily_files)) rows=$rows")
        catch exception
            errors[file_index] = sprint(showerror, exception)
        end
    end
    failed = findall(!isnothing, errors)
    isempty(failed) || error(join(("file $index: $(errors[index])" for index in failed), "; "))
    for file_index in eachindex(partial), (key, values) in partial[file_index]
        construction, compression = counts[key]
        construction .+= values[1]
        compression .+= values[2]
    end
    return counts
end

function _finalize_universes(config, provisional, support_counts, thresholds)
    minimum = Int(config["universe"]["minimum_construction_observations_per_belief"])
    minimum_origin = Int(config["universe"]["minimum_eligible_for_origin"])
    cap = Int(config["universe"]["maximum_eligible_by_liquidity"])
    evaluable = FinancialStrategyLibraryPanelV1.OriginUniverse[]
    status = Dict{String,Dict{String,Any}}()
    for origin in provisional.origins
        supported = NamedTuple[]
        profile_exclusions = Dict{String,Any}[]
        for row in provisional.candidates[origin.origin_id]
            construction, compression = support_counts[(origin.origin_id, row.permno)]
            if all(>=(minimum), construction) && all(>=(minimum), compression)
                push!(supported, merge(row, (;
                    construction_profile_counts = construction,
                    compression_profile_counts = compression,
                )))
            else
                push!(profile_exclusions, Dict{String,Any}(
                    "permno" => row.permno,
                    "reason" => "insufficient_profile_support",
                    "construction_counts" => construction,
                    "compression_counts" => compression,
                ))
            end
        end
        sort!(supported; by = row -> (-row.median_dollar_volume, row.permno))
        selected = collect(first(supported, min(cap, length(supported))))
        reference = provisional.reference_permnos[origin.origin_id]
        reason = if length(supported) < minimum_origin
            "fewer_than_minimum_supported_securities"
        elseif !any(row -> row.permno == reference, selected)
            "SPY_not_retained_after_support_and_liquidity_rules"
        else
            ""
        end
        row = Dict{String,Any}(
            "schema_version" => "financial-strategy-library-panel-v2-origin-status-v1",
            "origin_id" => origin.origin_id,
            "decision_year" => origin.decision_year,
            "decision_date" => provisional.decisions[origin.origin_id],
            "terminal" => true,
            "structurally_evaluable" => isempty(reason),
            "reason" => reason,
            "history_interval_candidate_count" => length(
                provisional.candidates[origin.origin_id],
            ) + length(provisional.exclusions[origin.origin_id]),
            "liquidity_eligible_count" => length(provisional.candidates[origin.origin_id]),
            "profile_supported_count" => length(supported),
            "selected_security_count" => length(selected),
            "reference_permno" => reference,
            "belief_thresholds" => thresholds[origin.origin_id],
            "preprofile_exclusions" => provisional.exclusions[origin.origin_id],
            "profile_exclusions" => profile_exclusions,
            "selected" => [Dict{String,Any}(
                "permno" => candidate.permno,
                "ticker" => candidate.ticker,
                "security_name_sha256" => candidate.security_name_sha256,
                "median_close" => candidate.median_close,
                "median_dollar_volume" => candidate.median_dollar_volume,
                "preorigin_daily_rows" => candidate.preorigin_daily_rows,
                "compression_liquidity_rows" => candidate.compression_liquidity_rows,
                "construction_profile_counts" => candidate.construction_profile_counts,
                "compression_profile_counts" => candidate.compression_profile_counts,
            ) for candidate in selected],
            "licensed_rows_included" => false,
        )
        status[origin.origin_id] = row
        _atomic_toml(joinpath(LOCAL_DATA_ROOT, "origin_status", "$(origin.origin_id).toml"), row)
        isempty(reason) || continue
        push!(evaluable, FinancialStrategyLibraryPanelV1.OriginUniverse(
            origin.origin_id,
            origin.decision_year,
            provisional.decisions[origin.origin_id],
            "$(origin.construction_start_year)-01-01",
            "$(origin.construction_end_year)-12-31",
            "$(origin.compression_start_year)-01-01",
            provisional.decisions[origin.origin_id],
            "$(origin.postdecision_year)-01-01",
            "$(origin.postdecision_year)-12-31",
            selected,
            length(provisional.candidates[origin.origin_id]),
            length(supported),
            reference,
        ))
    end
    return evaluable, status
end

function _evaluate_catalog(origin, series, state_by_date, config)
    runtime0 = _runtime_config(config; cost_bps = 0, risk_aversion = 3)
    amendment = _runtime_amendment()
    annualization = Int(config["operating_profiles"]["annualization_sessions"])
    scenario_registry = FinancialStrategyLibraryPanelV2Registries.scenario_rows()
    prior_strength = Float64(get(
        config["operating_profiles"],
        "regime_profile_prior_strength_sessions",
        0,
    ))
    evaluations = V2Evaluation[]
    for (strategy_index, strategy) in enumerate(_catalog(origin, config))
        rows = series[strategy.permno]
        observations = [row for row in rows if row.date <= origin.compression_end]
        dates = getfield.(observations, :date)
        backtest = FinancialStrategyLibraryPanelV1._backtest(
            strategy,
            observations,
            runtime0,
            amendment,
        )
        construction_indices = findall(
            date -> origin.construction_start <= date <= origin.construction_end,
            dates,
        )
        compression_indices_by_state = [findall(
            index -> origin.compression_start <= dates[index] <= origin.compression_end &&
                     get(state_by_date, dates[index], 0) == state,
            eachindex(dates),
        ) for state in 1:5]
        compression_indices = findall(
            date -> origin.compression_start <= date <= origin.compression_end,
            dates,
        )
        isempty(construction_indices) && error("construction window is empty")
        cost5 = backtest.net .- (5 / 10_000) .* backtest.turnover
        construction_score = _utility(
            cost5[construction_indices],
            annualization,
            3,
        )
        predecision_score = _utility(
            cost5[compression_indices],
            annualization,
            3,
        )
        profile = Float64[]
        for scenario in scenario_registry
            net = backtest.net .-
                  (Float64(scenario.transaction_cost_bps) / 10_000) .* backtest.turnover
            pooled_utility = _utility(
                net[compression_indices],
                annualization,
                scenario.risk_aversion,
            )
            state_indices = compression_indices_by_state[scenario.belief_state]
            state_utility = isempty(state_indices) ? pooled_utility : _utility(
                net[state_indices],
                annualization,
                scenario.risk_aversion,
            )
            push!(profile, _shrunk_regime_utility(
                state_utility,
                pooled_utility,
                length(state_indices),
                prior_strength,
            ))
        end
        compression_sessions = length(compression_indices)
        decisions = cld(compression_sessions, strategy.holding_horizon)
        work = FinancialStrategyLibraryPanelV2Registries.validation_work_units(
            signal_evaluations = compression_sessions,
            filter_evaluations = strategy.entry_filter == "always" ? 0 : compression_sessions,
            risk_updates = strategy.risk_constraint == "notional_cap_1" ? 0 : compression_sessions,
            position_decisions = decisions,
            exit_evaluations = strategy.exit_rule == "horizon" ? decisions : compression_sessions,
        )
        baseline = ("momentum_20", "always", 5, "unit", "horizon", "notional_cap_1")
        actual = (
            strategy.directional_signal,
            strategy.entry_filter,
            strategy.holding_horizon,
            strategy.sizing_rule,
            strategy.exit_rule,
            strategy.risk_constraint,
        )
        nonbaseline = count(index -> actual[index] != baseline[index], eachindex(actual))
        push!(evaluations, V2Evaluation(
            strategy,
            _strategy_id(strategy),
            construction_score,
            predecision_score,
            profile,
            work,
            FinancialStrategyLibraryPanelV2Registries.governance_review_units(nonbaseline),
        ))
        strategy_index % 1000 == 0 && _progress(
            "$(origin.origin_id) evaluated $strategy_index/$(length(origin.selected) * 96) grammar candidates",
        )
    end
    return evaluations
end

function _retain_ranked!(selected, group, depth, score)
    isempty(group) && return selected
    ordered = sort(copy(group); by = item -> (-score(item), item.strategy_id))
    cutoff = score(ordered[min(Int(depth), length(ordered))])
    for item in ordered
        score(item) >= cutoff || continue
        selected[item.strategy_id] = item
    end
    return selected
end

function _docket(evaluations, docket, config)
    selected = Dict{String,V2Evaluation}()
    include_per_security = Bool(get(
        config["source_dockets"],
        "include_per_security_rank_depth",
        true,
    ))
    if include_per_security
        by_security = Dict{Int,Vector{V2Evaluation}}()
        for item in evaluations
            push!(get!(by_security, item.strategy.permno, V2Evaluation[]), item)
        end
        for group in values(by_security)
            _retain_ranked!(
                selected,
                group,
                docket.per_security_rank_depth,
                item -> item.construction_score,
            )
        end
    end
    scenario_count = length(first(evaluations).scenario_profile)
    for scenario in 1:scenario_count
        _retain_ranked!(
            selected,
            evaluations,
            docket.per_scenario_rank_depth,
            item -> item.scenario_profile[scenario],
        )
    end
    for capability in FinancialStrategyLibraryPanelV2Registries.capability_rows()
        carriers = [
            item for item in evaluations if
            capability.capability_id in item.strategy.capability_ids
        ]
        _retain_ranked!(
            selected,
            carriers,
            docket.per_capability_carrier_depth,
            item -> item.construction_score,
        )
    end
    result = sort!(collect(values(selected)); by = item -> item.strategy_id)
    closure = Set(capability.capability_id for capability in FinancialStrategyLibraryPanelV2Registries.capability_rows())
    carried = Set{String}()
    for item in result
        union!(carried, item.strategy.capability_ids)
    end
    carried == closure || error("v2 source docket failed capability completion")
    return result
end

function _weight(item::V2Evaluation, schedule_id::AbstractString)
    schedule_id == "validation_work_units" && return item.validation_work_units
    schedule_id == "equal_active_strategy" && return 1
    schedule_id == "governance_review_units" && return item.governance_review_units
    error("unsupported burden schedule: $schedule_id")
end

function _instance(source, origin, docket_id, schedule_id, thresholds)
    ids = Any["mandatory_inactive_cash"]
    append!(ids, item.strategy_id for item in source)
    profiles = Matrix{ExactRational}(undef, length(ids), 30)
    profiles[1, :] .= zero(ExactRational)
    modules = Vector{Vector{Any}}(undef, length(ids))
    modules[1] = Any[]
    weights = Any[0]
    for (index, item) in enumerate(source)
        profiles[index + 1, :] .= _float_exact.(item.scenario_profile)
        modules[index + 1] = Any[item.strategy.capability_ids...]
        push!(weights, _weight(item, schedule_id))
    end
    provenance = JournalCompressionProvenance(
        :financial,
        "$(origin.origin_id):$docket_id:$schedule_id",
        "locked financial innovation-challenge panel v2 source docket";
        generator = "financial-strategy-library-panel-v2-execution-001",
        parent_hashes = [
            "source_specification_set_sha256" => _sha256_text(join(sort!(getfield.(source, :strategy_id)), '\n')),
            "belief_thresholds_sha256" => _sha256_text(join(string.(thresholds), '\n')),
        ],
        attributes = [
            "origin_id" => origin.origin_id,
            "docket_id" => String(docket_id),
            "schedule_id" => String(schedule_id),
            "postdecision_information_used" => "false",
        ],
        redistributable = false,
    )
    instance = journal_compression_instance_from_components(
        ids,
        Bool[true; falses(length(source))],
        weights,
        [scenario.scenario_id for scenario in FinancialStrategyLibraryPanelV2Registries.scenario_rows()],
        profiles,
        modules;
        tie_handling = JournalTieHandling(
            :declared_representative;
            declaration = "stable representative among any burden ties",
            stable_selector = "canonical v2 strategy identifier",
        ),
        provenance,
    )
    validate_journal_compression_instance(instance)
    return instance
end

function _menu_seed(origin_id, docket_id)
    matches = filter(
        row -> row.origin_id == origin_id && row.docket_id == docket_id,
        FinancialStrategyLibraryPanelV2Registries.seed_rows(),
    )
    return UInt64(only(matches).menu_seed)
end

function _multistart_seed(origin_id, docket_id)
    matches = filter(
        row -> row.origin_id == origin_id && row.docket_id == docket_id,
        FinancialStrategyLibraryPanelV2Registries.seed_rows(),
    )
    return UInt64(only(matches).multistart_seed)
end

function _menus(evaluations, source, origin_id, docket_id)
    source_ids = Set(item.strategy_id for item in source)
    pool = [item for item in evaluations if !(item.strategy_id in source_ids)]
    strata = Dict{Tuple{String,String,String},Vector{V2Evaluation}}()
    for item in pool
        key = (
            item.strategy.directional_signal,
            "$(item.strategy.directional_signal)+$(item.strategy.entry_filter)",
            item.strategy.risk_constraint,
        )
        push!(get!(strata, key, V2Evaluation[]), item)
    end
    length(strata) == 12 || error("masked candidate pool does not contain all 12 strata")
    rng = StableRNG(_menu_seed(origin_id, docket_id))
    ordered_keys = sort!(collect(keys(strata)); by = string)
    ordered_keys = ordered_keys[randperm(rng, length(ordered_keys))]
    ordered_groups = Dict{Tuple{String,String,String},Vector{V2Evaluation}}()
    positions = Dict{Tuple{String,String,String},Int}()
    for key in ordered_keys
        group = sort!(copy(strata[key]); by = item -> item.strategy_id)
        ordered_groups[key] = group[randperm(rng, length(group))]
        positions[key] = 1
    end
    menus = Vector{Vector{V2Evaluation}}()
    for menu_index in 1:32
        menu = V2Evaluation[]
        for slot in 1:8
            key = ordered_keys[mod1((menu_index - 1) * 8 + slot, length(ordered_keys))]
            group = ordered_groups[key]
            position = positions[key]
            push!(menu, group[mod1(position, length(group))])
            positions[key] = position + 1
        end
        length(unique(getfield.(menu, :strategy_id))) == 8 ||
            error("masked menu does not contain eight distinct candidates")
        push!(menus, sort!(menu; by = item -> item.strategy_id))
    end
    return menus
end

function _selection_payload(instance, selected)
    check = check_journal_compression_solution(instance, selected)
    indices = findall(selected)
    return Dict{String,Any}(
        "selected_strategy_indices" => indices,
        "selected_strategy_ids" => [string(instance.strategy_ids[index].id) for index in indices],
        "selected_active_strategy_count" => count(index -> !instance.mandatory[index], indices),
        "exact_burden" => _exact_text(check.exact_burden),
        "mandatory_retained" => check.mandatory_retained,
        "frontier_preserved" => check.frontier_preserved,
        "closure_preserved" => check.closure_preserved,
        "exact_feasible" => check.exact_feasible,
    )
end

function _solve_mip(instance, config; warm_start = :none)
    stress = config["computational_stress_block"]
    result = solve_journal_compression_mip(
        instance;
        random_seed = Int(stress["highs_random_seed"]),
        time_limit = Float64(stress["mip_time_limit_seconds"]),
        relative_mip_gap_tolerance = Float64(stress["mip_relative_gap"]),
        absolute_mip_gap_tolerance = Float64(stress["mip_absolute_gap"]),
        warm_start,
        warm_start_source = "registered innovation-safe weighted greedy endpoint",
        exact_crosscheck = :none,
    )
    selection = isnothing(result.reconstructed_candidate) ? nothing :
        BitVector(result.reconstructed_candidate)
    return result, selection
end

function _arm_record(arm_id, status, instance, selected; extra = Dict{String,Any}())
    payload = Dict{String,Any}(
        "arm_id" => String(arm_id),
        "terminal" => true,
        "status" => String(status),
        "candidate_returned" => !isnothing(selected),
    )
    if !isnothing(selected)
        payload["selection"] = _selection_payload(instance, selected)
    end
    merge!(payload, extra)
    return payload
end

function _solve_arms(instance, source, origin_id, docket_id, schedule_id, config)
    predecision_scores = ExactRational[
        zero(ExactRational);
        _float_exact.(getfield.(source, :predecision_score))
    ]
    source_selected = trues(length(instance.strategy_ids))
    greedy = solve_journal_compression_weighted_greedy_reverse_delete(instance)
    frontier_instance = frontier_only_journal_instance(instance)
    frontier_greedy = solve_journal_compression_weighted_greedy_reverse_delete(frontier_instance)
    population_mode = String(get(
        config["arms"],
        "population_primary_mode",
        "exact_mip",
    ))
    if population_mode == "greedy_reverse_delete"
        arms = Dict{String,Any}()
        arms["source"] = _arm_record("source", "FROZEN_SOURCE", instance, source_selected)
        arms["innovation_safe_greedy"] = _arm_record(
            "innovation_safe_greedy",
            string(greedy.status),
            instance,
            BitVector(greedy.selected),
        )
        deferred_stress = Dict{String,Any}(
            "admitted" => false,
            "reason" => "population MIP and timing deferred to separate computational benchmark",
            "minimum_carriers_before_preprocessing" => 0,
            "residual_variables" => 0,
            "residual_requirements" => 0,
            "warmup_outside_timed_region" => true,
            "timed_scope" => "HiGHS optimization search only",
            "steady_state_repetitions" => Int(config["computational_stress_block"]["steady_state_repetitions"]),
            "search_wall_ns" => String[],
            "timing_deferred_to_separate_benchmark" => true,
        )
        arms["innovation_safe_exact"] = _arm_record(
            "innovation_safe_exact",
            "DEFERRED_TO_COMPUTATIONAL_BENCHMARK",
            instance,
            nothing,
            extra = Dict{String,Any}("stress_block" => deferred_stress),
        )
        arms["frontier_only_exact"] = _arm_record(
            "frontier_only_exact",
            "DEFERRED_TO_COMPUTATIONAL_BENCHMARK",
            frontier_instance,
            nothing,
        )
        arms["innovation_safe_multistart_64"] = _arm_record(
            "innovation_safe_multistart_64",
            "DEFERRED_TO_COMPUTATIONAL_BENCHMARK",
            instance,
            nothing,
            extra = Dict{String,Any}(
                "starts" => 64,
                "seed" => string(_multistart_seed(origin_id, docket_id)),
            ),
        )
        matched = frontier_only_budget_matched_selection(
            instance,
            BitVector(frontier_greedy.selected),
            BitVector(greedy.selected),
            predecision_scores,
        )
        slack = matched.exact_burden_cap - matched.exact_burden
        arms["frontier_only_budget_matched"] = _arm_record(
            "frontier_only_budget_matched",
            "EXACTLY_RECHECKED_GREEDY_BUDGET_MATCH",
            frontier_instance,
            matched.selected,
            extra = Dict{String,Any}(
                "parent_endpoint" => "frontier_only_weighted_greedy_reverse_delete",
                "budget_endpoint" => "innovation_safe_weighted_greedy_reverse_delete",
                "exact_burden_cap" => _exact_text(matched.exact_burden_cap),
                "exact_unused_slack" => _exact_text(slack),
                "added_strategy_indices" => matched.additions,
                "closure_recovered" => matched.closure_recovered,
            ),
        )
        return arms
    end
    population_mode == "exact_mip" || error("unsupported population arm mode: $population_mode")
    safe_mip, safe_selected = _solve_mip(instance, config; warm_start = greedy.selected)
    frontier_mip, frontier_selected = _solve_mip(
        frontier_instance,
        config;
        warm_start = frontier_greedy.selected,
    )
    multistart = solve_journal_compression_multistart_random(
        instance;
        seed = _multistart_seed(origin_id, docket_id),
        starts = 64,
    )
    arms = Dict{String,Any}()
    arms["source"] = _arm_record("source", "FROZEN_SOURCE", instance, source_selected)
    arms["innovation_safe_greedy"] = _arm_record(
        "innovation_safe_greedy",
        string(greedy.status),
        instance,
        BitVector(greedy.selected),
    )
    arms["innovation_safe_multistart_64"] = _arm_record(
        "innovation_safe_multistart_64",
        string(multistart.status),
        instance,
        BitVector(multistart.selected),
        extra = Dict{String,Any}(
            "starts" => 64,
            "seed" => string(_multistart_seed(origin_id, docket_id)),
        ),
    )
    arms["innovation_safe_exact"] = _arm_record(
        "innovation_safe_exact",
        string(safe_mip.status),
        instance,
        safe_selected,
        extra = Dict{String,Any}(
            "solver_claimed_optimal" => safe_mip.solver_claimed_optimal,
            "exact_global_optimum_verified" => safe_mip.exact_global_optimum_verified,
            "solver_optimality_is_formal_proof" => false,
            "termination_status" => safe_mip.diagnostics.termination_status,
            "optimization_wall_ns" => string(safe_mip.runtime.optimization_wall_ns),
        ),
    )
    preprocessing = preprocess_tagged_cover(exact_tagged_cover_model(instance))
    carriers = [count(instance.coverage[row, :]) for row in axes(instance.coverage, 1)]
    stress = config["computational_stress_block"]
    stress_admitted = minimum(carriers) >= Int(stress["minimum_carriers_per_requirement_before_preprocessing"]) &&
                      length(preprocessing.reduced.strategy_ids) >= Int(stress["minimum_residual_variables_after_preprocessing"]) &&
                      length(preprocessing.reduced.requirements) >= Int(stress["minimum_residual_requirements_after_preprocessing"])
    stress_record = Dict{String,Any}(
        "admitted" => stress_admitted,
        "minimum_carriers_before_preprocessing" => minimum(carriers),
        "residual_variables" => length(preprocessing.reduced.strategy_ids),
        "residual_requirements" => length(preprocessing.reduced.requirements),
        "warmup_outside_timed_region" => true,
        "timed_scope" => "HiGHS optimization search only",
        "steady_state_repetitions" => Int(stress["steady_state_repetitions"]),
        "search_wall_ns" => String[],
        "timing_deferred_to_separate_benchmark" => false,
    )
    inline_timing = Bool(get(stress, "inline_population_timing", true))
    if stress_admitted && inline_timing
        for _ in 1:Int(stress["steady_state_repetitions"])
            repetition, _ = _solve_mip(instance, config; warm_start = greedy.selected)
            push!(stress_record["search_wall_ns"], string(repetition.runtime.optimization_wall_ns))
        end
    elseif stress_admitted
        stress_record["timing_deferred_to_separate_benchmark"] = true
    end
    arms["innovation_safe_exact"]["stress_block"] = stress_record
    arms["frontier_only_exact"] = _arm_record(
        "frontier_only_exact",
        string(frontier_mip.status),
        frontier_instance,
        frontier_selected,
        extra = Dict{String,Any}(
            "solver_claimed_optimal" => frontier_mip.solver_claimed_optimal,
            "exact_global_optimum_verified" => frontier_mip.exact_global_optimum_verified,
            "solver_optimality_is_formal_proof" => false,
            "termination_status" => frontier_mip.diagnostics.termination_status,
            "optimization_wall_ns" => string(frontier_mip.runtime.optimization_wall_ns),
        ),
    )
    if isnothing(safe_selected) || isnothing(frontier_selected)
        arms["frontier_only_budget_matched"] = _arm_record(
            "frontier_only_budget_matched",
            "STRUCTURAL_PARENT_UNAVAILABLE",
            frontier_instance,
            nothing,
        )
    else
        matched = frontier_only_budget_matched_selection(
            instance,
            frontier_selected,
            safe_selected,
            predecision_scores,
        )
        slack = matched.exact_burden_cap - matched.exact_burden
        arms["frontier_only_budget_matched"] = _arm_record(
            "frontier_only_budget_matched",
            "EXACTLY_RECHECKED_BUDGET_MATCH",
            frontier_instance,
            matched.selected,
            extra = Dict{String,Any}(
                "exact_burden_cap" => _exact_text(matched.exact_burden_cap),
                "exact_unused_slack" => _exact_text(slack),
                "added_strategy_indices" => matched.additions,
                "closure_recovered" => matched.closure_recovered,
            ),
        )
    end
    return arms
end

function _choice(menu, instance, arm)
    arm["candidate_returned"] === true || return Dict{String,Any}(
        "available" => false,
        "reason" => "arm_has_no_exactly_rechecked_endpoint",
    )
    selection = arm["selection"]
    selected = falses(length(instance.strategy_ids))
    selected[Int.(selection["selected_strategy_indices"])] .= true
    capabilities = retained_capability_ids(instance, selected)
    ordered = sort(copy(menu); by = item -> (-item.predecision_score, item.strategy_id))
    for (rank, candidate) in enumerate(ordered)
        issubset(Set(candidate.strategy.capability_ids), capabilities) || continue
        return Dict{String,Any}(
            "available" => true,
            "candidate_id" => candidate.strategy_id,
            "predecision_rank" => rank,
            "used_cash_fallback" => false,
        )
    end
    return Dict{String,Any}(
        "available" => true,
        "candidate_id" => "mandatory_inactive_cash",
        "predecision_rank" => 0,
        "used_cash_fallback" => true,
    )
end

function _serialize_predecision(
    origin,
    docket,
    source,
    menus,
    schedule_instances,
    schedule_arms,
    thresholds,
    config,
)
    menu_rows = [Dict{String,Any}(
        "menu_id" => "$(origin.origin_id)|$(docket.docket_id)|M$(lpad(index, 2, '0'))",
        "candidate_ids" => getfield.(menu, :strategy_id),
        "candidate_predecision_scores" => getfield.(menu, :predecision_score),
        "candidate_capabilities" => [collect(item.strategy.capability_ids) for item in menu],
    ) for (index, menu) in enumerate(menus)]
    choices = Dict{String,Any}()
    primary_instance = schedule_instances[PRIMARY_SCHEDULE]
    primary_arms = schedule_arms[PRIMARY_SCHEDULE]
    for arm in FinancialStrategyLibraryPanelV2Registries.arm_rows()
        choices[arm.arm_id] = [
            merge(
                Dict{String,Any}("menu_id" => menu_rows[index]["menu_id"]),
                _choice(menu, primary_instance, primary_arms[arm.arm_id]),
            ) for (index, menu) in enumerate(menus)
        ]
    end
    payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v2-predecision-v1",
        "origin_id" => origin.origin_id,
        "docket_id" => docket.docket_id,
        "created_at_utc" => _utc_now(),
        "postdecision_opened" => false,
        "primary_safe_arm_id" => String(get(config["arms"], "primary_safe_arm", "innovation_safe_exact")),
        "primary_comparator_arm_id" => "frontier_only_budget_matched",
        "belief_thresholds" => thresholds,
        "source_strategy_count" => length(source),
        "menu_seed" => string(_menu_seed(origin.origin_id, docket.docket_id)),
        "multistart_seed" => string(_multistart_seed(origin.origin_id, docket.docket_id)),
        "seed_namespace" => FinancialStrategyLibraryPanelV2Registries.seed_namespace(),
        "menu_generation_algorithm" => "stable_rng_rotating_12_strata_v1",
        "source_strategy_ids" => getfield.(source, :strategy_id),
        "source_capabilities" => [collect(item.strategy.capability_ids) for item in source],
        "source_profiles_exact" => [[_exact_text(_float_exact(value)) for value in item.scenario_profile] for item in source],
        "source_predecision_scores" => getfield.(source, :predecision_score),
        "source_weights" => Dict{String,Any}(
            schedule.schedule_id => [_weight(item, schedule.schedule_id) for item in source]
            for schedule in FinancialStrategyLibraryPanelV2Registries.burden_rows()
        ),
        "instance_sha256" => Dict{String,Any}(
            schedule_id => journal_compression_instance_sha256(instance)
            for (schedule_id, instance) in schedule_instances
        ),
        "arms" => schedule_arms,
        "menus" => menu_rows,
        "choices" => choices,
        "licensed_rows_included" => false,
    )
    path = joinpath(PREDECISION_ROOT, origin.origin_id, "$(docket.docket_id).toml")
    _atomic_toml(path, payload)
    return payload
end

function _seal_predecision(execution_lock_aggregate)
    aggregate = _directory_aggregate(PREDECISION_ROOT)
    file_count = sum(length(files) for (_, _, files) in walkdir(PREDECISION_ROOT))
    payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v2-predecision-seal-v1",
        "experiment_id" => "financial-strategy-library-panel-v2",
        "sealed_at_utc" => _utc_now(),
        "execution_lock_aggregate_sha256" => execution_lock_aggregate,
        "predecision_directory_sha256" => aggregate,
        "predecision_file_count" => file_count,
        "postdecision_opened_before_seal" => false,
        "verified_before_postdecision_open" => true,
    )
    path = joinpath(LOCAL_RESULTS_ROOT, "PREDECISION_SEAL.toml")
    _atomic_toml(path, payload)
    return verify_predecision_seal()
end

function verify_predecision_seal()
    path = joinpath(LOCAL_RESULTS_ROOT, "PREDECISION_SEAL.toml")
    isfile(path) || error("predecision seal is absent")
    payload = TOML.parsefile(path)
    payload["postdecision_opened_before_seal"] === false ||
        error("predecision seal records an information-firewall violation")
    observed = _directory_aggregate(PREDECISION_ROOT)
    observed == payload["predecision_directory_sha256"] ||
        error("predecision directory aggregate differs from its seal")
    return payload
end

function _strategy_from_id(identifier::AbstractString)
    parts = split(identifier, '|')
    length(parts) == 8 || error("v2 strategy identifier is malformed")
    origin_id, permno, signal, filter, horizon, sizing, exit_rule, risk = parts
    return _strategy(
        origin_id,
        parse(Int, permno),
        signal,
        filter,
        parse(Int, horizon),
        sizing,
        exit_rule,
        risk,
    )
end

function _postdecision_score(candidate_id, origin, series, config)
    candidate_id == "mandatory_inactive_cash" && return Dict{String,Any}(
        "available" => true,
        "score" => 0.0,
        "reason" => "cash_fallback",
        "observed_sessions" => 0,
        "cash_sessions" => 0,
    )
    strategy = _strategy_from_id(candidate_id)
    haskey(series, strategy.permno) || return Dict{String,Any}(
        "available" => false,
        "reason" => "selected_candidate_security_series_absent",
        "observed_sessions" => 0,
        "cash_sessions" => 0,
    )
    reference = series[origin.reference_permno]
    calendar = sort!(String[
        row.date for row in reference if
        origin.postdecision_start <= row.date <= origin.postdecision_end
    ])
    observations = [row for row in series[strategy.permno] if row.date <= origin.postdecision_end]
    runtime = _runtime_config(config; cost_bps = 5, risk_aversion = 3)
    backtest = FinancialStrategyLibraryPanelV1._backtest(
        strategy,
        observations,
        runtime,
        _runtime_amendment(),
    )
    indices = findall(
        row -> origin.postdecision_start <= row.date <= origin.postdecision_end,
        observations,
    )
    dates = String[observations[index].date for index in indices]
    net = Float64[backtest.net[index] for index in indices]
    delisting_dates = String[
        observations[index].date for index in indices if
        !(observations[index].delisting_flag in ("", "N"))
    ]
    explicit_delisting = isempty(delisting_dates) ? nothing : last(delisting_dates)
    if !isnothing(explicit_delisting)
        keep = findall(date -> date <= explicit_delisting, dates)
        dates = dates[keep]
        net = net[keep]
    end
    outcome = full_calendar_postdecision_utility(
        calendar,
        dates,
        net;
        explicit_delisting_date = explicit_delisting,
        annualization_sessions = Int(config["operating_profiles"]["annualization_sessions"]),
        risk_aversion = 3,
        minimum_sessions = Int(config["innovation_challenges"]["minimum_full_calendar_sessions"]),
    )
    return Dict{String,Any}(
        "available" => outcome.available,
        "score" => outcome.available ? outcome.score : 0.0,
        "reason" => outcome.reason,
        "observed_sessions" => outcome.observed_sessions,
        "cash_sessions" => outcome.cash_sessions,
        "explicit_delisting_to_cash" => !isnothing(explicit_delisting),
    )
end

function _postdecision_docket(origin, docket_id, series, config)
    pre_path = joinpath(PREDECISION_ROOT, origin.origin_id, "$docket_id.toml")
    pre = TOML.parsefile(pre_path)
    choices = pre["choices"]
    score_cache = Dict{String,Dict{String,Any}}()
    for arm in FinancialStrategyLibraryPanelV2Registries.arm_rows(), choice in choices[arm.arm_id]
        get(choice, "available", false) === true || continue
        candidate_id = String(choice["candidate_id"])
        haskey(score_cache, candidate_id) && continue
        score_cache[candidate_id] = _postdecision_score(candidate_id, origin, series, config)
    end
    menu_rows = Dict{String,Any}[]
    for menu_index in 1:32
        arm_outcomes = Dict{String,Any}()
        for arm in FinancialStrategyLibraryPanelV2Registries.arm_rows()
            choice = choices[arm.arm_id][menu_index]
            if get(choice, "available", false) !== true
                arm_outcomes[arm.arm_id] = Dict{String,Any}(
                    "available" => false,
                    "reason" => String(choice["reason"]),
                )
                continue
            end
            candidate_id = String(choice["candidate_id"])
            outcome = score_cache[candidate_id]
            arm_outcomes[arm.arm_id] = Dict{String,Any}(
                "available" => outcome["available"],
                "candidate_id" => candidate_id,
                "score" => outcome["score"],
                "reason" => outcome["reason"],
                "used_cash_fallback" => choice["used_cash_fallback"],
                "observed_sessions" => outcome["observed_sessions"],
                "cash_sessions" => outcome["cash_sessions"],
            )
        end
        safe_arm_id = String(get(config["arms"], "primary_safe_arm", "innovation_safe_exact"))
        comparator_arm_id = "frontier_only_budget_matched"
        safe = arm_outcomes[safe_arm_id]
        comparator = arm_outcomes[comparator_arm_id]
        complete = get(safe, "available", false) === true &&
                   get(comparator, "available", false) === true
        push!(menu_rows, Dict{String,Any}(
            "menu_id" => pre["menus"][menu_index]["menu_id"],
            "terminal" => true,
            "complete_primary_pair" => complete,
            "heldout_innovation_utility_delta" => complete ?
                Float64(safe["score"]) - Float64(comparator["score"]) : 0.0,
            "primary_unavailable_reason" => complete ? "" :
                "one_or_both_frozen_candidate_outcomes_unavailable",
            "same_primary_candidate" => get(safe, "candidate_id", "") ==
                                        get(comparator, "candidate_id", ""),
            "arm_outcomes" => arm_outcomes,
        ))
    end
    complete_count = count(row -> row["complete_primary_pair"] === true, menu_rows)
    payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v2-postdecision-v1",
        "origin_id" => origin.origin_id,
        "docket_id" => docket_id,
        "postdecision_opened_at_utc" => _utc_now(),
        "predecision_file_sha256" => _sha256_file(pre_path),
        "predecision_seal_verified_before_open" => true,
        "primary_safe_arm_id" => String(get(config["arms"], "primary_safe_arm", "innovation_safe_exact")),
        "primary_comparator_arm_id" => "frontier_only_budget_matched",
        "complete_primary_menu_pairs" => complete_count,
        "origin_docket_menu_gate_passed" => complete_count >= 24,
        "menus" => menu_rows,
        "licensed_rows_included" => false,
    )
    _atomic_toml(
        joinpath(POSTDECISION_ROOT, origin.origin_id, "$docket_id.toml"),
        payload,
    )
    return payload
end

function _quantile(values::Vector{Float64}, probability::Float64)
    isempty(values) && return NaN
    ordered = sort(copy(values))
    index = clamp(ceil(Int, probability * length(ordered)), 1, length(ordered))
    return ordered[index]
end

function _mean(values::Vector{Float64})
    isempty(values) && return NaN
    return sum(values) / length(values)
end

function _analyze(status, postdecision, config, execution_lock_aggregate)
    structurally_evaluable = sort!(String[
        origin_id for (origin_id, row) in status if
        row["structurally_evaluable"] === true
    ])
    origin_docket_rows = Dict{String,Any}[]
    by_origin = Dict{String,Vector{Float64}}()
    for origin_id in structurally_evaluable,
        docket in FinancialStrategyLibraryPanelV2Registries.docket_rows()
        payload = postdecision[(origin_id, docket.docket_id)]
        values = Float64[
            row["heldout_innovation_utility_delta"] for row in payload["menus"] if
            row["complete_primary_pair"] === true
        ]
        gate = length(values) >= 24
        estimate = gate ? _mean(values) : 0.0
        gate && push!(get!(by_origin, origin_id, Float64[]), estimate)
        push!(origin_docket_rows, Dict{String,Any}(
            "origin_id" => origin_id,
            "docket_id" => docket.docket_id,
            "complete_menu_pairs" => length(values),
            "menu_gate_passed" => gate,
            "origin_docket_mean" => estimate,
            "reason" => gate ? "" : "fewer_than_24_complete_menu_pairs",
        ))
    end
    origin_rows = Dict{String,Any}[]
    for origin_id in structurally_evaluable
        values = get(by_origin, origin_id, Float64[])
        pass = length(values) == length(FinancialStrategyLibraryPanelV2Registries.docket_rows())
        push!(origin_rows, Dict{String,Any}(
            "origin_id" => origin_id,
            "menu_gate_passed_both_dockets" => pass,
            "available_docket_count" => length(values),
            "cross_docket_origin_mean" => pass ? _mean(values) : 0.0,
            "reason" => pass ? "" : "one_or_both_dockets_failed_menu_gate",
        ))
    end
    passing = [row for row in origin_rows if row["menu_gate_passed_both_dockets"] === true]
    values = Float64[row["cross_docket_origin_mean"] for row in passing]
    structural_gate = length(structurally_evaluable) >=
                      Int(config["availability_gates"]["minimum_structurally_evaluable_origins"])
    fraction = isempty(structurally_evaluable) ? 0.0 :
        length(passing) / length(structurally_evaluable)
    fraction_gate = fraction >=
                    Float64(config["availability_gates"]["minimum_origin_fraction_passing_menu_gate"])
    availability_gate = structural_gate && fraction_gate
    interval = [NaN, NaN]
    if availability_gate && !isempty(values)
        digest = sha256(codeunits(
            FinancialStrategyLibraryPanelV2Registries.seed_namespace() * "|primary-bootstrap",
        ))
        seed = zero(UInt64)
        for byte in digest[1:8]
            seed = (seed << 8) | UInt64(byte)
        end
        rng = StableRNG(seed)
        bootstrap = Float64[]
        for _ in 1:Int(config["analysis"]["bootstrap_repetitions"])
            draw = Float64[values[randperm(rng, length(values))[1]] for _ in eachindex(values)]
            push!(bootstrap, _mean(draw))
        end
        interval = [_quantile(bootstrap, 0.025), _quantile(bootstrap, 0.975)]
    end
    summary = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v2-analysis-v1",
        "experiment_id" => "financial-strategy-library-panel-v2",
        "generated_at_utc" => _utc_now(),
        "execution_lock_aggregate_sha256" => execution_lock_aggregate,
        "predecision_seal_sha256" => _sha256_file(joinpath(LOCAL_RESULTS_ROOT, "PREDECISION_SEAL.toml")),
        "structurally_evaluable_origins" => length(structurally_evaluable),
        "origins_passing_both_docket_menu_gates" => length(passing),
        "origin_passing_fraction" => fraction,
        "availability_gate_passed" => availability_gate,
        "primary_status" => availability_gate ? "REGISTERED_AVAILABILITY_GATE_PASSED" :
            "INCONCLUSIVE_BY_REGISTERED_AVAILABILITY_GATE",
        "primary_origin_count" => length(values),
        "primary_mean" => availability_gate ? _mean(values) : 0.0,
        "primary_median" => availability_gate ? _quantile(values, 0.5) : 0.0,
        "primary_iqr" => availability_gate ? [_quantile(values, 0.25), _quantile(values, 0.75)] : [0.0, 0.0],
        "primary_range" => availability_gate ? [minimum(values), maximum(values)] : [0.0, 0.0],
        "primary_positive_count" => availability_gate ? count(>(0), values) : 0,
        "primary_zero_count" => availability_gate ? count(iszero, values) : 0,
        "primary_negative_count" => availability_gate ? count(<(0), values) : 0,
        "primary_origin_bootstrap_percentile_interval" => interval,
        "bootstrap_seed_namespace" => FinancialStrategyLibraryPanelV2Registries.seed_namespace(),
        "primary_safe_arm_id" => String(get(config["arms"], "primary_safe_arm", "innovation_safe_exact")),
        "primary_comparator_arm_id" => "frontier_only_budget_matched",
        "bootstrap_is_descriptive_not_population_or_causal" => true,
        "solver_optimality_is_formal_proof" => false,
        "licensed_rows_included" => false,
    )
    _atomic_toml(joinpath(ANALYSIS_ROOT, "PRIMARY_SUMMARY.toml"), summary)
    _atomic_toml(joinpath(ANALYSIS_ROOT, "ORIGIN_DOCKET_CONTRASTS.toml"), Dict(
        "schema_version" => "financial-strategy-library-panel-v2-origin-docket-contrasts-v1",
        "rows" => origin_docket_rows,
    ))
    _atomic_toml(joinpath(ANALYSIS_ROOT, "ORIGIN_CONTRASTS.toml"), Dict(
        "schema_version" => "financial-strategy-library-panel-v2-origin-contrasts-v1",
        "rows" => origin_rows,
    ))
    return summary
end

function _write_environment(execution_lock_aggregate)
    LinearAlgebra.BLAS.set_num_threads(1)
    payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v2-environment-v1",
        "recorded_at_utc" => _utc_now(),
        "julia_version" => string(VERSION),
        "julia_threads" => Threads.nthreads(),
        "blas_threads" => LinearAlgebra.BLAS.get_num_threads(),
        "highs_threads_per_model" => 1,
        "execution_lock_aggregate_sha256" => execution_lock_aggregate,
        "dependency_manifest_sha256" => _sha256_file(joinpath(REPOSITORY_ROOT, "julia", "Manifest.toml")),
        "licensed_rows_included" => false,
    )
    _atomic_toml(joinpath(LOCAL_RESULTS_ROOT, "ENVIRONMENT.toml"), payload)
    return payload
end

function _freeze_origin_predecision(origin, series, states, thresholds, config)
    evaluations = _evaluate_catalog(origin, series, states, config)
    origin_structural_ok = true
    for docket in FinancialStrategyLibraryPanelV2Registries.docket_rows()
        _progress("phase 2/4: $(origin.origin_id) $(docket.docket_id) freezing source, menus, and arms")
        source = _docket(evaluations, docket, config)
        menus = _menus(evaluations, source, origin.origin_id, docket.docket_id)
        instances = Dict{String,Any}()
        arms = Dict{String,Any}()
        for schedule in FinancialStrategyLibraryPanelV2Registries.burden_rows()
            instance = _instance(
                source,
                origin,
                docket.docket_id,
                schedule.schedule_id,
                thresholds,
            )
            instances[schedule.schedule_id] = instance
            arms[schedule.schedule_id] = _solve_arms(
                instance,
                source,
                origin.origin_id,
                docket.docket_id,
                schedule.schedule_id,
                config,
            )
        end
        _serialize_predecision(
            origin,
            docket,
            source,
            menus,
            instances,
            arms,
            thresholds,
            config,
        )
        primary_arms = arms[PRIMARY_SCHEDULE]
        safe_arm_id = String(get(config["arms"], "primary_safe_arm", "innovation_safe_exact"))
        origin_structural_ok &= primary_arms[safe_arm_id]["candidate_returned"] === true
        origin_structural_ok &= primary_arms["frontier_only_budget_matched"]["candidate_returned"] === true
    end
    return origin_structural_ok
end

function run_all()
    execution_lock_aggregate = _require_execution_lock()
    existing_results = isdir(LOCAL_RESULTS_ROOT) ? Set(readdir(LOCAL_RESULTS_ROOT)) : Set{String}()
    isempty(existing_results) || error("v2 local results are not clean at execution start")
    config = load_execution_config()
    existing_data = isdir(LOCAL_DATA_ROOT) ? Set(readdir(LOCAL_DATA_ROOT)) : Set{String}()
    reuse_master = haskey(config, "master_panel") &&
                   Bool(config["master_panel"]["reuse_existing"])
    expected_data = reuse_master ? Set(["master_market_panel"]) : Set{String}()
    existing_data == expected_data || error(
        "v2 local data execution boundary mismatch: expected $(sort!(collect(expected_data)))",
    )
    metadata = source_metadata(config)
    _write_environment(execution_lock_aggregate)
    _progress("phase 1/4: hashing source delivery and validating schemas")
    _source_schema_audit(config, metadata)
    _progress(reuse_master ?
        "phase 1/4: validating the adopted 2000-2025 common-equity and ETF master panel" :
        "phase 1/4: building the 2000-2025 common-equity and ETF master panel")
    market_intervals = _load_market_intervals(metadata.paths.security_history)
    master_chunks, market_intervals, master_manifest = reuse_master ?
        _reuse_master_market_panel(config, metadata.paths.daily_files, market_intervals) :
        _stage_master_market_panel(
            config,
            metadata.paths.daily_files,
            market_intervals,
            execution_lock_aggregate,
        )
    _atomic_toml(joinpath(LOCAL_RESULTS_ROOT, "MASTER_PANEL_SUMMARY.toml"), Dict(
        "schema_version" => "financial-strategy-library-panel-v2-master-summary-v1",
        "study_start" => STUDY_START,
        "study_end" => STUDY_END,
        "instrument_classes" => master_manifest["instrument_classes"],
        "eligible_permno_count" => master_manifest["eligible_permno_count"],
        "retained_master_rows" => master_manifest["retained_master_rows"],
        "chunk_count" => master_manifest["chunk_count"],
        "source_quality" => master_manifest["source_quality"],
        "adopted_existing_master_panel" => reuse_master,
        "master_directory_aggregate_sha256" => reuse_master ?
            String(config["master_panel"]["adopted_directory_aggregate_sha256"]) :
            _directory_aggregate(joinpath(LOCAL_DATA_ROOT, "master_market_panel")),
        "seed_namespace" => FinancialStrategyLibraryPanelV2Registries.seed_namespace(),
        "licensed_rows_included" => false,
    ))
    _progress("phase 1/4: constructing point-in-time liquid instrument universes")
    provisional = _provisional_universes_master(config, master_chunks, market_intervals)
    thresholds, states, calendars = _reference_states_master(
        config,
        provisional,
        master_chunks,
    )
    origins, status = _complete_case_universes_master(
        config,
        provisional,
        master_chunks,
        states,
        calendars,
        thresholds,
    )
    _progress("phase 1/4 complete: $(length(origins))/20 origins structurally eligible before docket construction")

    _progress("phase 2/4: opening origin-scoped predecision views from the frozen master panel")
    structural = _extract_master_observations(
        master_chunks,
        origins;
        phase = :structural,
        calendars,
    )
    structural_ok = trues(length(origins))
    Threads.@threads :dynamic for origin_index in eachindex(origins)
        structural_ok[origin_index] = _freeze_origin_predecision(
            origins[origin_index],
            structural[origins[origin_index].origin_id],
            states[origins[origin_index].origin_id],
            thresholds[origins[origin_index].origin_id],
            config,
        )
    end
    for (origin_index, origin) in enumerate(origins)
        structural_ok[origin_index] && continue
        status[origin.origin_id]["structurally_evaluable"] = false
        status[origin.origin_id]["reason"] = "one_or_more_primary_structural_arms_unavailable"
        _atomic_toml(
            joinpath(LOCAL_DATA_ROOT, "origin_status", "$(origin.origin_id).toml"),
            status[origin.origin_id];
            replace = true,
        )
    end
    empty!(structural)
    GC.gc()
    seal = _seal_predecision(execution_lock_aggregate)
    _progress("phase 2/4 complete: predecision seal $(seal["predecision_directory_sha256"])")

    _progress("phase 3/4: predecision seal verified; opening registered postdecision windows")
    verify_predecision_seal()
    quality = Dict{String,Any}()
    post_series = _extract_master_observations(
        master_chunks,
        origins,
        phase = :postdecision,
        diagnostics = quality,
    )
    _atomic_toml(joinpath(LOCAL_RESULTS_ROOT, "POSTDECISION_SOURCE_QUALITY.toml"), Dict(
        "schema_version" => "financial-strategy-library-panel-v2-postdecision-source-quality-v1",
        "origins" => quality,
        "licensed_rows_included" => false,
    ))
    post_jobs = [
        (origin, docket) for origin in origins,
        docket in FinancialStrategyLibraryPanelV2Registries.docket_rows()
    ]
    post_payloads = Vector{Any}(undef, length(post_jobs))
    Threads.@threads :dynamic for job_index in eachindex(post_jobs)
        post_payloads[job_index] = _postdecision_docket(
            post_jobs[job_index][1],
            post_jobs[job_index][2].docket_id,
            post_series[post_jobs[job_index][1].origin_id],
            config,
        )
    end
    postdecision = Dict(
        (post_jobs[index][1].origin_id, post_jobs[index][2].docket_id) => post_payloads[index]
        for index in eachindex(post_jobs)
    )
    _progress("phase 3/4 complete: all frozen menu choices have terminal outcomes")
    summary = _analyze(status, postdecision, config, execution_lock_aggregate)
    _progress("phase 4/4 complete: $(summary["primary_status"])")
    return summary
end

function run_synthetic_smoke()
    config = load_execution_config()
    provenance = JournalCompressionProvenance(
        :financial,
        "v2-execution-smoke",
        "synthetic v2 execution smoke";
        redistributable = true,
    )
    instance = journal_compression_instance_from_components(
        ["cash", "a", "b", "bundle"],
        [true, false, false, false],
        [0, 2, 3, 4],
        ["s1", "s2"],
        [0 0; 2 0; 0 2; 2 2],
        [String[], ["c1"], ["c2"], ["c1", "c2"]];
        provenance,
    )
    greedy = solve_journal_compression_weighted_greedy_reverse_delete(instance)
    mip, selected = _solve_mip(instance, config; warm_start = greedy.selected)
    isnothing(selected) && error("synthetic v2 execution smoke returned no MIP candidate")
    check = check_journal_compression_solution(instance, selected)
    check.exact_feasible || error("synthetic v2 execution smoke candidate is infeasible")
    return Dict{String,Any}(
        "passed" => true,
        "solver_claimed_optimal" => mip.solver_claimed_optimal,
        "exact_global_optimum_verified" => mip.exact_global_optimum_verified,
        "exact_burden" => _exact_text(check.exact_burden),
    )
end

function run_structural_smoke()
    config = load_execution_config()
    origin = (
        origin_id = "FSLP2-O2005",
        selected = [(permno = 1,), (permno = 2,), (permno = 3,)],
    )
    evaluations = V2Evaluation[]
    for (index, strategy) in enumerate(_catalog(origin, config))
        profile = fill(index / 1000, 30)
        push!(evaluations, V2Evaluation(
            strategy,
            _strategy_id(strategy),
            index / 1000,
            index / 1000,
            profile,
            1 + (index % 7),
            11 + (index % 7),
        ))
    end
    docket = first(FinancialStrategyLibraryPanelV2Registries.docket_rows())
    source = _docket(evaluations, docket, config)
    menus = _menus(evaluations, source, origin.origin_id, "focused_docket")
    instance = _instance(source, origin, "focused_docket", PRIMARY_SCHEDULE, [0.1, 0.2, 0.3, 0.4])
    arms = _solve_arms(
        instance,
        source,
        "FSLP2-O2005",
        "focused_docket",
        PRIMARY_SCHEDULE,
        config,
    )
    safe_id = String(get(config["arms"], "primary_safe_arm", "innovation_safe_exact"))
    safe = arms[safe_id]
    comparator = arms["frontier_only_budget_matched"]
    safe["candidate_returned"] === true || error("structural smoke safe arm unavailable")
    comparator["candidate_returned"] === true || error("structural smoke comparator unavailable")
    length(menus) == 32 || error("structural smoke menu count mismatch")
    return Dict{String,Any}(
        "passed" => true,
        "source_strategy_count" => length(source),
        "menu_count" => length(menus),
        "safe_burden" => safe["selection"]["exact_burden"],
        "comparator_burden" => comparator["selection"]["exact_burden"],
    )
end

end
