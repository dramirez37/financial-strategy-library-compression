module BuildFinancialStrategyLibraryPanelV3UniverseCensus

using Parquet
using SHA: sha256
using Tables
using TOML

export build_census, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v3.toml",
)
const MASTER_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2",
    "local_data",
    "master_market_panel",
)
const MASTER_MANIFEST_PATH = joinpath(MASTER_ROOT, "MASTER_MANIFEST.toml")
const INTERVAL_PATH = joinpath(MASTER_ROOT, "security_intervals.parquet")
const ORIGIN_PATH = joinpath(EXPERIMENT_ROOT, "registry", "ORIGIN_REGISTRY.csv")
const UNIVERSE_PATH = joinpath(EXPERIMENT_ROOT, "registry", "UNIVERSE_REGISTRY.csv")
const LOCAL_ROOT = joinpath(EXPERIMENT_ROOT, "local_data", "universe_census")
const LOCAL_SELECTION_PATH = joinpath(LOCAL_ROOT, "UNIVERSE_SELECTIONS.toml")
const PUBLIC_ROOT = joinpath(EXPERIMENT_ROOT, "source_census")
const PUBLIC_CENSUS_PATH = joinpath(PUBLIC_ROOT, "SOURCE_CENSUS.toml")
const PUBLIC_CSV_PATH = joinpath(PUBLIC_ROOT, "SOURCE_CENSUS.csv")
const PUBLIC_MANIFEST_PATH = joinpath(PUBLIC_ROOT, "SOURCE_CENSUS_MANIFEST.toml")
const SELECTED_COLUMNS = [
    ["permno"],
    ["date"],
    ["close"],
    ["volume"],
    ["delisting_flag"],
    ["return_flag"],
]

mutable struct YearStats
    rows::Int
    ordinary_return_rows::Int
    invalid_price_rows::Int
    invalid_volume_rows::Int
    date_xor::UInt64
    date_sum::UInt64
    last_date::String
    last_close::Union{Missing,Float64}
    dollar_volumes::Vector{Float64}
    delisting_flag_rows::Int
    resolved_delisting_flag_rows::Int
end

YearStats() = YearStats(0, 0, 0, 0, 0, 0, "", missing, Float64[], 0, 0)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

_sha256_text(value) = bytes2hex(sha256(codeunits(String(value))))

function _directory_hashes(directory)
    result = Dict{String,String}()
    for (root, _, files) in walkdir(directory), file in files
        path = joinpath(root, file)
        result[relpath(path, directory)] = _sha256_file(path)
    end
    return result
end

function _directory_aggregate(hashes)
    canonical = join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    )
    return _sha256_text(canonical)
end

function _csv_rows(path)
    lines = filter(!isempty, strip.(readlines(path)))
    isempty(lines) && error("empty registry: $(relpath(path, REPOSITORY_ROOT))")
    header = split(first(lines), ',')
    rows = Dict{String,String}[]
    for line in Iterators.drop(lines, 1)
        fields = split(line, ','; keepempty = true)
        length(fields) == length(header) || error("registry row width changed")
        push!(rows, Dict(String(key) => String(value) for (key, value) in zip(header, fields)))
    end
    return rows
end

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _atomic_write(path, content)
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, content)
    end
    mv(temporary, path; force = true)
    return path
end

function _write_or_check(path, content, check)
    if check
        isfile(path) || error("census artifact is absent: $(relpath(path, REPOSITORY_ROOT))")
        read(path, String) == content || error(
            "census artifact changed: $(relpath(path, REPOSITORY_ROOT))",
        )
    else
        _atomic_write(path, content)
    end
    return path
end

function _date_token(date, cache)
    return get!(cache, date) do
        digest = sha256(codeunits(date))
        foldl(
            (accumulator, byte) -> (accumulator << 8) | UInt64(byte),
            @view(digest[1:8]);
            init = UInt64(0),
        )
    end
end

function _merge!(target::YearStats, source::YearStats)
    target.rows += source.rows
    target.ordinary_return_rows += source.ordinary_return_rows
    target.invalid_price_rows += source.invalid_price_rows
    target.invalid_volume_rows += source.invalid_volume_rows
    target.date_xor ⊻= source.date_xor
    target.date_sum += source.date_sum
    if source.last_date > target.last_date
        target.last_date = source.last_date
        target.last_close = source.last_close
    end
    append!(target.dollar_volumes, source.dollar_volumes)
    target.delisting_flag_rows += source.delisting_flag_rows
    target.resolved_delisting_flag_rows += source.resolved_delisting_flag_rows
    return target
end

function _scan_chunk!(stats, date_cache, path)
    file = Parquet.File(path)
    try
        cursor = Parquet.RecordCursor(file; colnames = SELECTED_COLUMNS)
        for record in cursor
            ismissing(record.permno) && continue
            ismissing(record.date) && error("master panel contains a missing date")
            permno = Int(record.permno)
            date = String(record.date)
            year = parse(Int, date[1:4])
            2000 <= year <= 2025 || continue
            entry = get!(stats, (permno, year), YearStats())
            entry.rows += 1
            return_flag = ismissing(record.return_flag) ? "" : String(record.return_flag)
            return_flag == "NA" && (entry.ordinary_return_rows += 1)
            ismissing(record.close) && (entry.invalid_price_rows += 1)
            ismissing(record.volume) && (entry.invalid_volume_rows += 1)
            token = _date_token(date, date_cache)
            entry.date_xor ⊻= token
            entry.date_sum += token
            if date > entry.last_date
                entry.last_date = date
                entry.last_close = ismissing(record.close) ? missing : Float64(record.close)
            end
            if year >= 2003 && !ismissing(record.close) && !ismissing(record.volume) &&
               record.close > 0 && record.volume >= 0
                push!(entry.dollar_volumes, Float64(record.close) * Float64(record.volume))
            end
            delisting_flag = ismissing(record.delisting_flag) ? "" : String(record.delisting_flag)
            if !(delisting_flag in ("", "N"))
                entry.delisting_flag_rows += 1
                return_flag == "NA" && (entry.resolved_delisting_flag_rows += 1)
            end
        end
    finally
        close(file)
    end
    return stats
end

function _scan_master(chunks)
    thread_slots = Threads.maxthreadid()
    partials = [Dict{Tuple{Int,Int},YearStats}() for _ in 1:thread_slots]
    date_caches = [Dict{String,UInt64}() for _ in 1:thread_slots]
    Threads.@threads :static for chunk_index in eachindex(chunks)
        thread = Threads.threadid()
        _scan_chunk!(partials[thread], date_caches[thread], chunks[chunk_index])
        chunk_index % 20 == 0 && println(
            stderr,
            "v3 census scanned chunk $chunk_index/$(length(chunks)) on thread $thread",
        )
    end
    result = Dict{Tuple{Int,Int},YearStats}()
    for partial in partials, (key, source) in partial
        _merge!(get!(result, key, YearStats()), source)
    end
    return result
end

function _load_intervals()
    table = Parquet.read_parquet(INTERVAL_PATH; use_threads = false)
    columns = Tables.columntable(table)
    required = (
        :permno,
        :start_date,
        :end_date,
        :ticker,
        :security_name,
        :instrument_class,
    )
    all(name -> name in propertynames(columns), required) ||
        error("security-interval artifact omits a required column")
    return [(
        permno = Int(columns.permno[index]),
        start_date = String(columns.start_date[index]),
        end_date = String(columns.end_date[index]),
        ticker = String(columns.ticker[index]),
        security_name = String(columns.security_name[index]),
        instrument_class = String(columns.instrument_class[index]),
    ) for index in eachindex(columns.permno)]
end

function _active_intervals(intervals, date)
    result = Dict{Int,NamedTuple}()
    for interval in intervals
        interval.start_date <= date <= interval.end_date || continue
        interval.instrument_class in ("common_equity", "plain_etf") || continue
        haskey(result, interval.permno) && error(
            "overlapping point-in-time security intervals for PERMNO $(interval.permno)",
        )
        result[interval.permno] = interval
    end
    return result
end

function _median!(values)
    isempty(values) && return NaN
    sort!(values)
    middle = length(values) ÷ 2
    return isodd(length(values)) ? values[middle + 1] :
        (values[middle] + values[middle + 1]) / 2
end

function _calendar_complete(stats, permno, years, spy_permno)
    for year in years
        security = get(stats, (permno, year), nothing)
        reference = get(stats, (spy_permno, year), nothing)
        isnothing(security) && return false
        isnothing(reference) && error("SPY calendar is absent for $year")
        security.rows == reference.rows || return false
        security.date_xor == reference.date_xor || return false
        security.date_sum == reference.date_sum || return false
        security.ordinary_return_rows == security.rows || return false
        iszero(security.invalid_price_rows) || return false
        iszero(security.invalid_volume_rows) || return false
    end
    return true
end

function _compression_liquidity(stats, permno, years)
    values = Float64[]
    for year in years
        entry = get(stats, (permno, year), nothing)
        isnothing(entry) || append!(values, entry.dollar_volumes)
    end
    return _median!(values), length(values)
end

function _future_delisting_counts(stats, permno, years)
    flagged = 0
    resolved = 0
    for year in years
        entry = get(stats, (permno, year), nothing)
        isnothing(entry) && continue
        flagged += entry.delisting_flag_rows
        resolved += entry.resolved_delisting_flag_rows
    end
    return flagged, resolved
end

function _spy_permno(active)
    matches = [
        interval.permno for interval in values(active) if
        interval.ticker == "SPY" && interval.instrument_class == "plain_etf"
    ]
    length(matches) == 1 || error("expected exactly one point-in-time SPY identifier")
    return only(matches)
end

function _cell(
    origin,
    universe,
    active,
    stats,
    decision_date,
    spy_permno,
    config,
)
    instrument_class = universe["instrument_class"]
    active_rows = sort!(
        [interval for interval in values(active) if interval.instrument_class == instrument_class];
        by = interval -> interval.permno,
    )
    keywords = uppercase.(String.(config["universes"]["plain_etf_exclude_name_keywords"]))
    full_years = origin.formation_start_year:origin.compression_end_year
    compression_years = origin.compression_start_year:origin.compression_end_year
    candidates = NamedTuple[]
    complete_count = 0
    excluded_complex_count = 0
    for interval in active_rows
        if instrument_class == "plain_etf" &&
           any(keyword -> occursin(keyword, uppercase(interval.security_name)), keywords)
            excluded_complex_count += 1
            continue
        end
        _calendar_complete(stats, interval.permno, full_years, spy_permno) || continue
        complete_count += 1
        decision_stats = stats[(interval.permno, origin.compression_end_year)]
        decision_stats.last_date == decision_date || continue
        decision_close = decision_stats.last_close
        ismissing(decision_close) && continue
        decision_close >= parse(Float64, universe["minimum_price"]) || continue
        median_dollar_volume, liquidity_sessions = _compression_liquidity(
            stats,
            interval.permno,
            compression_years,
        )
        liquidity_sessions >= Int(config["universes"]["minimum_compression_liquidity_sessions"]) ||
            continue
        median_dollar_volume >= parse(Float64, universe["minimum_trailing_dollar_volume"]) ||
            continue
        future_flagged, future_resolved = _future_delisting_counts(
            stats,
            interval.permno,
            (origin.proposal_year, origin.evaluation_year),
        )
        push!(candidates, (;
            permno = interval.permno,
            ticker = interval.ticker,
            security_name_sha256 = _sha256_text(interval.security_name),
            decision_close = Float64(decision_close),
            median_dollar_volume,
            liquidity_sessions,
            complete_predecision_sessions = sum(stats[(spy_permno, year)].rows for year in full_years),
            future_delisting_flag_rows = future_flagged,
            future_resolved_delisting_flag_rows = future_resolved,
        ))
    end
    sort!(candidates; by = row -> (-row.median_dollar_volume, row.permno))
    cap = parse(Int, universe["liquidity_cap"])
    minimum = parse(Int, universe["minimum_eligible"])
    selected = collect(first(candidates, min(cap, length(candidates))))
    passed = length(candidates) >= minimum
    status = passed ? "PASSED" : "FAILED_MINIMUM_ELIGIBLE"
    expected_sessions = sum(stats[(spy_permno, year)].rows for year in full_years)
    public = Dict{String,Any}(
        "origin_id" => origin.origin_id,
        "universe_id" => universe["universe_id"],
        "instrument_class" => instrument_class,
        "role" => universe["role"],
        "decision_year" => origin.compression_decision_year,
        "decision_date" => decision_date,
        "status" => status,
        "active_interval_count" => length(active_rows),
        "complex_etf_exclusion_count" => excluded_complex_count,
        "complete_predecision_count" => complete_count,
        "liquidity_eligible_count" => length(candidates),
        "selected_count" => length(selected),
        "required_minimum" => minimum,
        "liquidity_cap" => cap,
        "expected_predecision_sessions" => expected_sessions,
        "selected_future_delisting_flag_rows" => sum(
            row.future_delisting_flag_rows for row in selected;
            init = 0,
        ),
        "selected_future_resolved_delisting_flag_rows" => sum(
            row.future_resolved_delisting_flag_rows for row in selected;
            init = 0,
        ),
    )
    local_cell = copy(public)
    local_cell["selected"] = [Dict{String,Any}(
        "rank" => rank,
        "permno" => row.permno,
        "ticker" => row.ticker,
        "security_name_sha256" => row.security_name_sha256,
        "decision_close" => row.decision_close,
        "median_dollar_volume" => row.median_dollar_volume,
        "liquidity_sessions" => row.liquidity_sessions,
        "complete_predecision_sessions" => row.complete_predecision_sessions,
        "future_delisting_flag_rows" => row.future_delisting_flag_rows,
        "future_resolved_delisting_flag_rows" => row.future_resolved_delisting_flag_rows,
    ) for (rank, row) in enumerate(selected)]
    return public, local_cell
end

function _origin_rows()
    return [(
        origin_id = row["origin_id"],
        compression_decision_year = parse(Int, row["compression_decision_year"]),
        formation_start_year = parse(Int, row["formation_start_year"]),
        compression_start_year = parse(Int, row["compression_start_year"]),
        compression_end_year = parse(Int, row["compression_end_year"]),
        proposal_year = parse(Int, row["proposal_year"]),
        evaluation_year = parse(Int, row["evaluation_year"]),
    ) for row in _csv_rows(ORIGIN_PATH)]
end

function _csv_text(cells)
    header = [
        "origin_id",
        "universe_id",
        "instrument_class",
        "status",
        "decision_year",
        "decision_date",
        "active_interval_count",
        "complete_predecision_count",
        "liquidity_eligible_count",
        "selected_count",
        "required_minimum",
        "liquidity_cap",
        "expected_predecision_sessions",
        "selected_future_delisting_flag_rows",
        "selected_future_resolved_delisting_flag_rows",
    ]
    io = IOBuffer()
    println(io, join(header, ','))
    for cell in cells
        println(io, join((cell[key] for key in header), ','))
    end
    return String(take!(io))
end

function _source_contract(config, manifest)
    isfile(MASTER_MANIFEST_PATH) || error("sealed v2 master manifest is absent")
    _sha256_file(MASTER_MANIFEST_PATH) == config["source"]["historical_development_manifest_sha256"] ||
        error("sealed v2 master manifest hash changed")
    hashes = _directory_hashes(MASTER_ROOT)
    aggregate = _directory_aggregate(hashes)
    aggregate == config["source"]["historical_development_directory_aggregate_sha256"] ||
        error("sealed v2 master directory aggregate changed")
    manifest["retained_master_rows"] == sum(Int(chunk["row_count"]) for chunk in manifest["chunks"]) ||
        error("sealed master row count does not reconcile")
    for chunk in manifest["chunks"]
        path = String(chunk["path"])
        hashes[path] == String(chunk["sha256"]) || error("master chunk hash changed: $path")
    end
    interval_manifest = TOML.parsefile(joinpath(MASTER_ROOT, "security_intervals.toml"))
    hashes["security_intervals.parquet"] == interval_manifest["parquet_sha256"] ||
        error("security interval hash changed")
    return hashes, aggregate
end

function build_census(; check = false)
    config = TOML.parsefile(CONFIG_PATH)
    config["language"] == "Julia" || error("v3 main language is not Julia")
    config["v3_outcomes_opened"] === false || error("v3 outcome lock is not active")
    config["universes"]["future_survival_may_define_membership"] === false ||
        error("future survival was enabled as a universe rule")
    config["universes"]["predecision_calendar_completeness"] == 1.0 ||
        error("v3 census no longer requires full predecision data")
    manifest = TOML.parsefile(MASTER_MANIFEST_PATH)
    _, source_aggregate = _source_contract(config, manifest)
    chunks = [joinpath(MASTER_ROOT, String(chunk["path"])) for chunk in manifest["chunks"]]
    intervals = _load_intervals()
    stats = _scan_master(chunks)

    public_cells = Dict{String,Any}[]
    local_cells = Dict{String,Any}[]
    origins = _origin_rows()
    universes = _csv_rows(UNIVERSE_PATH)
    for origin in origins
        provisional_date = "$(origin.compression_decision_year)-12-31"
        provisional_active = _active_intervals(intervals, provisional_date)
        provisional_spy = _spy_permno(provisional_active)
        reference = get(stats, (provisional_spy, origin.compression_decision_year), nothing)
        isnothing(reference) && error("SPY calendar is absent for $(origin.origin_id)")
        decision_date = reference.last_date
        active = _active_intervals(intervals, decision_date)
        spy_permno = _spy_permno(active)
        spy_permno == provisional_spy || error("SPY identity changed inside an origin")
        for universe in universes
            public, local_cell = _cell(
                origin,
                universe,
                active,
                stats,
                decision_date,
                spy_permno,
                config,
            )
            push!(public_cells, public)
            push!(local_cells, local_cell)
        end
    end
    sort!(public_cells; by = row -> (row["origin_id"], row["universe_id"]))
    sort!(local_cells; by = row -> (row["origin_id"], row["universe_id"]))

    local_payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-universe-selections-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "source_directory_aggregate_sha256" => source_aggregate,
        "outcome_values_accessed" => false,
        "licensed_identifier_rows_included" => true,
        "public_promotion_permitted" => false,
        "cells" => local_cells,
    )
    local_text = _toml_text(local_payload)
    local_hash = _sha256_text(local_text)
    public_payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-source-census-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "source_directory_aggregate_sha256" => source_aggregate,
        "source_manifest_sha256" => _sha256_file(MASTER_MANIFEST_PATH),
        "local_selection_sha256" => local_hash,
        "origin_count" => length(origins),
        "universe_count" => length(universes),
        "cell_count" => length(public_cells),
        "primary_common_equity_cells_passed" => count(
            row -> row["role"] == "primary" && row["status"] == "PASSED",
            public_cells,
        ),
        "etf_replication_cells_passed" => count(
            row -> row["instrument_class"] == "plain_etf" && row["status"] == "PASSED",
            public_cells,
        ),
        "full_predecision_calendar_required" => true,
        "future_survival_used_for_membership" => false,
        "outcome_values_accessed" => false,
        "licensed_rows_included" => false,
        "cells" => public_cells,
    )
    public_text = _toml_text(public_payload)
    csv_text = _csv_text(public_cells)
    manifest_payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-source-census-manifest-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "source_census_toml_sha256" => _sha256_text(public_text),
        "source_census_csv_sha256" => _sha256_text(csv_text),
        "local_selection_sha256" => local_hash,
        "config_sha256" => _sha256_file(CONFIG_PATH),
        "data_contract_sha256" => _sha256_file(joinpath(EXPERIMENT_ROOT, "DATA_CONTRACT.md")),
        "script_sha256" => _sha256_file(@__FILE__),
        "outcome_values_accessed" => false,
        "licensed_rows_included" => false,
    )
    manifest_text = _toml_text(manifest_payload)

    _write_or_check(LOCAL_SELECTION_PATH, local_text, check)
    _write_or_check(PUBLIC_CENSUS_PATH, public_text, check)
    _write_or_check(PUBLIC_CSV_PATH, csv_text, check)
    _write_or_check(PUBLIC_MANIFEST_PATH, manifest_text, check)
    println("V3_SOURCE_CENSUS_PASSED")
    println("common-equity cells passed: $(public_payload["primary_common_equity_cells_passed"])/$(length(origins))")
    println("ETF replication cells passed: $(public_payload["etf_replication_cells_passed"])/$(length(origins))")
    println("outcome values accessed: false")
    return public_payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    build_census(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    BuildFinancialStrategyLibraryPanelV3UniverseCensus.main()
end
