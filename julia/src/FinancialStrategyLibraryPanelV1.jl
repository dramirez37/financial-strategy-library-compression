module FinancialStrategyLibraryPanelV1

using Dates
using LinearAlgebra
using Random: rand, randperm
using SHA: sha256
using StableRNGs: StableRNG
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "..", "scripts", "create_financial_strategy_library_panel_v1_registries.jl"))
using .FinancialStrategyLibraryPanelV1Registries

export DailyObservation,
       OriginUniverse,
       PanelStrategy,
       audit_instance_result,
       build_origin_instances,
       build_synthetic_smoke_instances,
       construct_origin_universes,
       evaluate_postdecision,
       extract_daily_series,
       extract_origin_series,
       load_panel_config,
       registered_job_keys,
       run_algorithm_suite,
       source_paths,
       toml_text

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v1.toml",
)
const AMENDMENT_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
    "amendments",
    "EXECUTION_AMENDMENT_001.toml",
)
const AMENDMENT_002_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
    "amendments",
    "EXECUTION_AMENDMENT_002.toml",
)
const AMENDMENT_003_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
    "amendments",
    "EXECUTION_AMENDMENT_003.toml",
)
const AMENDMENT_004_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
    "amendments",
    "EXECUTION_AMENDMENT_004.toml",
)
const AMENDMENT_005_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
    "amendments",
    "EXECUTION_AMENDMENT_005.toml",
)
const ALGORITHM_IDS = (
    "jump_highs_tagged_cover",
    "requirement_mask_dp",
    "complete_enumeration",
    "weighted_greedy_reverse_delete",
    "heaviest_safe_first",
    "declared_source_order",
    "multistart_random_rechecked_deletion_32",
)
const SCHEDULE_IDS = (
    "validation_work_units",
    "equal_active_strategy",
    "governance_review_units",
)

_require(condition::Bool, message::AbstractString) = condition ? true : error(message)
_sha256_text(text::AbstractString) = bytes2hex(sha256(codeunits(text)))
_exact_text(value::Rational) = "$(numerator(value))//$(denominator(value))"
_float_exact(value::Float64) = rationalize(BigInt, value; tol = 0)

function toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

struct SecurityInterval
    permno::Int
    start_date::String
    end_date::String
    ticker::String
    security_name::String
    security_type::String
    security_subtype::String
    active::String
end

struct DailyObservation
    date::String
    total_return::Float64
    close::Float64
    volume::Float64
    delisting_flag::String
    return_missing_flag::String
end

struct OriginUniverse
    origin_id::String
    decision_year::Int
    decision_date::String
    construction_start::String
    construction_end::String
    compression_start::String
    compression_end::String
    postdecision_start::String
    postdecision_end::String
    selected::Vector{NamedTuple}
    candidate_count::Int
    eligible_count::Int
    reference_permno::Int
end

struct PanelStrategy
    origin_id::String
    permno::Int
    directional_signal::String
    entry_filter::String
    holding_horizon::Int
    sizing_rule::String
    exit_rule::String
    risk_constraint::String
    capability_ids::Tuple{Vararg{String}}
    specification_sha256::String
end

struct StrategyEvaluation
    strategy::PanelStrategy
    construction_score::Float64
    construction_profile::Vector{Float64}
    compression_profile::Vector{Float64}
    compression_sessions::Int
    validation_work_units::Int
    governance_review_units::Int
end

mutable struct UniverseStats
    daily_rows::Int
    compression_rows::Int
    closes::Vector{Float64}
    dollar_volumes::Vector{Float64}
    invalid_liquidity_rows::Int
end

UniverseStats() = UniverseStats(0, 0, Float64[], Float64[], 0)

function load_panel_config(path::AbstractString = CONFIG_PATH)
    config = TOML.parsefile(path)
    config["schema_version"] == "financial-strategy-library-panel-design-v1" ||
        error("unsupported financial panel design schema")
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v1" ||
        error("unsupported financial panel execution amendment")
    amendment["study_outcome_observed_before_amendment"] === false ||
        error("the execution amendment is not prospective")
    successor = TOML.parsefile(AMENDMENT_002_PATH)
    successor["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v2" ||
        error("unsupported successor execution amendment")
    successor["amendment_id"] == "AMENDMENT_002" ||
        error("unexpected successor execution amendment identifier")
    successor["study_instance_constructed_before_amendment"] === false ||
        error("the return-quality amendment followed instance construction")
    successor["algorithm_or_solver_outcome_observed_before_amendment"] === false ||
        error("the return-quality amendment followed an algorithm outcome")
    amendment["predecessor_amendment_id"] = amendment["amendment_id"]
    amendment["amendment_id"] = successor["amendment_id"]
    amendment["successor_amendment"] = successor
    amendment["return_rule"] = successor["return_rule"]
    amendment["environment_recovery"] = successor["environment_recovery"]
    failure_amendment = TOML.parsefile(AMENDMENT_003_PATH)
    failure_amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v3" ||
        error("unsupported failure-persistence execution amendment")
    failure_amendment["amendment_id"] == "AMENDMENT_003" ||
        error("unexpected failure-persistence amendment identifier")
    failure_amendment["registered_seed_consumed_before_amendment"] === false ||
        error("the failure-persistence amendment followed seed consumption")
    failure_amendment["algorithm_or_solver_outcome_observed_before_amendment"] === false ||
        error("the failure-persistence amendment followed an algorithm outcome")
    amendment["predecessor_amendment_id"] = amendment["amendment_id"]
    amendment["amendment_id"] = failure_amendment["amendment_id"]
    amendment["failure_amendment"] = failure_amendment
    amendment["failure_persistence"] = failure_amendment["failure_persistence"]
    scalability_amendment = TOML.parsefile(AMENDMENT_004_PATH)
    scalability_amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v4" ||
        error("unsupported scalability execution amendment")
    scalability_amendment["amendment_id"] == "AMENDMENT_004" ||
        error("unexpected scalability amendment identifier")
    scalability_amendment["algorithm_or_solver_outcome_persisted_before_amendment"] === false ||
        error("scalability amendment followed a persisted algorithm outcome")
    scalability_amendment["algorithm_or_solver_outcome_inspected_before_amendment"] === false ||
        error("scalability amendment followed an inspected algorithm outcome")
    amendment["predecessor_amendment_id"] = amendment["amendment_id"]
    amendment["amendment_id"] = scalability_amendment["amendment_id"]
    amendment["scalability_amendment"] = scalability_amendment
    amendment["threading"] = scalability_amendment["threading"]
    amendment["resume"] = scalability_amendment["resume"]
    amendment["progress"] = scalability_amendment["progress"]
    progress_amendment = TOML.parsefile(AMENDMENT_005_PATH)
    progress_amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v5" ||
        error("unsupported progress execution amendment")
    progress_amendment["amendment_id"] == "AMENDMENT_005" ||
        error("unexpected progress execution amendment identifier")
    progress_amendment["predecessor_amendment_id"] == "AMENDMENT_004" ||
        error("unexpected progress amendment predecessor")
    progress_amendment["algorithm_or_solver_outcome_persisted_before_amendment"] === false ||
        error("progress amendment followed a persisted algorithm outcome")
    progress_amendment["algorithm_or_solver_outcome_inspected_before_amendment"] === false ||
        error("progress amendment followed an inspected algorithm outcome")
    amendment["predecessor_amendment_id"] = amendment["amendment_id"]
    amendment["amendment_id"] = progress_amendment["amendment_id"]
    amendment["progress_amendment"] = progress_amendment
    amendment["preparation_resume"] = progress_amendment["preparation_resume"]
    amendment["progress"] = progress_amendment["progress"]
    return config, amendment
end

function source_paths(config, source_root::AbstractString)
    source = config["source"]
    root = normpath(source_root)
    security = joinpath(root, String(source["security_history"]))
    daily = [joinpath(root, String(path)) for path in source["daily_files"]]
    return (root = root, security_history = security, daily_files = daily)
end

function _split_csv(line::AbstractString)
    fields = String[]
    buffer = IOBuffer()
    quoted = false
    index = firstindex(line)
    while index <= lastindex(line)
        character = line[index]
        if quoted
            if character == '"'
                next_index = nextind(line, index)
                if next_index <= lastindex(line) && line[next_index] == '"'
                    write(buffer, '"')
                    index = next_index
                else
                    quoted = false
                end
            else
                write(buffer, character)
            end
        elseif character == '"'
            position(buffer) == 0 || error("quote begins inside an unquoted CSV field")
            quoted = true
        elseif character == ','
            push!(fields, String(take!(buffer)))
        else
            write(buffer, character)
        end
        index = nextind(line, index)
    end
    quoted && error("unterminated quoted CSV field")
    push!(fields, String(take!(buffer)))
    return fields
end

function _positions(header::AbstractVector{<:AbstractString}, required)
    result = Dict{String,Int}()
    length(header) == length(unique(header)) || error("source has duplicate columns")
    for name in required
        position = findfirst(==(name), header)
        isnothing(position) && error("source is missing required column: $name")
        result[name] = position
    end
    return result
end

function _with_daily_file(f::Function, path::AbstractString)
    open(`gzip -cd -- $path`, "r") do io
        return f(io)
    end
end

function _report_scan(
    progress_callback,
    stage::AbstractString,
    state::AbstractString,
    file_index::Int,
    file_count::Int,
    source_rows_scanned::Int,
)
    isnothing(progress_callback) && return nothing
    progress_callback((;
        stage = String(stage),
        state = String(state),
        file_index,
        file_count,
        source_rows_scanned,
    ))
    return nothing
end

function _parse_float(value::AbstractString)
    parsed = tryparse(Float64, strip(value))
    return isnothing(parsed) || !isfinite(parsed) ? nothing : parsed
end

function _positive_close(fields, positions)
    close = _parse_float(fields[positions["dlyclose"]])
    if isnothing(close) || close <= 0
        close = _parse_float(fields[positions["dlyprc"]])
        isnothing(close) || (close = abs(close))
    end
    return isnothing(close) || close <= 0 ? nothing : close
end

function _load_security_intervals(path::AbstractString, config)
    required = String.(config["source"]["required_security_history_columns"]["columns"])
    intervals = SecurityInterval[]
    open(path, "r") do io
        header = strip.(_split_csv(chomp(readline(io))))
        positions = _positions(header, required)
        for line in eachline(io)
            fields = _split_csv(chomp(line))
            length(fields) == length(header) || error("security-history CSV width mismatch")
            permno = tryparse(Int, strip(fields[positions["permno"]]))
            isnothing(permno) && continue
            push!(intervals, SecurityInterval(
                permno,
                strip(fields[positions["secinfostartdt"]]),
                strip(fields[positions["secinfoenddt"]]),
                strip(fields[positions["ticker"]]),
                strip(fields[positions["securitynm"]]),
                strip(fields[positions["securitytype"]]),
                strip(fields[positions["securitysubtype"]]),
                strip(fields[positions["securityactiveflg"]]),
            ))
        end
    end
    return intervals
end

_contains(interval::SecurityInterval, date::AbstractString) =
    interval.start_date <= date <= interval.end_date

function _origin_interval_rows(intervals, date, config)
    universe = config["universe"]
    by_permno = Dict{Int,SecurityInterval}()
    for interval in intervals
        _contains(interval, date) || continue
        interval.security_type == universe["security_type"] || continue
        interval.security_subtype == universe["security_subtype"] || continue
        interval.active == "Y" || continue
        haskey(by_permno, interval.permno) && error(
            "overlapping origin-valid security-history rows for PERMNO $(interval.permno)",
        )
        by_permno[interval.permno] = interval
    end
    return by_permno
end

function _reference_permnos(intervals, origin_rows, config)
    reference = String(config["universe"]["required_reference_ticker"])
    result = Dict{String,Int}()
    for origin in origin_rows
        provisional = "$(origin.decision_year)-12-31"
        matches = [
            row for row in intervals if _contains(row, provisional) &&
            row.ticker == reference && row.security_type == config["universe"]["security_type"] &&
            row.security_subtype == config["universe"]["security_subtype"]
        ]
        length(matches) == 1 || error(
            "expected one origin-valid $reference security row for $(origin.origin_id)",
        )
        result[origin.origin_id] = only(matches).permno
    end
    return result
end

function _decision_dates(
    daily_files,
    origins,
    reference_permnos,
    config;
    progress_callback = nothing,
)
    targets = Dict(origin.origin_id => "$(origin.decision_year)-12-31" for origin in origins)
    dates = Dict(origin.origin_id => "" for origin in origins)
    origin_by_permno = Dict{Int,Vector{NamedTuple}}()
    for origin in origins
        push!(
            get!(origin_by_permno, reference_permnos[origin.origin_id], NamedTuple[]),
            (origin_id = origin.origin_id, year = origin.decision_year),
        )
    end
    required = String.(config["source"]["required_daily_columns"]["columns"])
    source_rows_scanned = 0
    file_count = length(daily_files)
    for (file_index, path) in enumerate(daily_files)
        _report_scan(
            progress_callback,
            "decision-session scan",
            "file-started",
            file_index,
            file_count,
            source_rows_scanned,
        )
        _with_daily_file(path) do io
            header = strip.(_split_csv(chomp(readline(io))))
            positions = _positions(header, required)
            for line in eachline(io)
                source_rows_scanned += 1
                source_rows_scanned % 1_000_000 == 0 && _report_scan(
                    progress_callback,
                    "decision-session scan",
                    "running",
                    file_index,
                    file_count,
                    source_rows_scanned,
                )
                fields = _split_csv(chomp(line))
                length(fields) == length(header) || error("daily-security CSV width mismatch")
                permno = tryparse(Int, strip(fields[positions["permno"]]))
                isnothing(permno) && continue
                candidates = get(origin_by_permno, permno, NamedTuple[])
                isempty(candidates) && continue
                date = strip(fields[positions["dlycaldt"]])
                for origin in candidates
                    startswith(date, "$(origin.year)-") || continue
                    date <= targets[origin.origin_id] || continue
                    dates[origin.origin_id] = max(dates[origin.origin_id], date)
                end
            end
        end
        _report_scan(
            progress_callback,
            "decision-session scan",
            "file-completed",
            file_index,
            file_count,
            source_rows_scanned,
        )
    end
    all(!isempty, values(dates)) || error("a registered origin has no SPY decision session")
    return dates
end

function _median(values::Vector{Float64})
    isempty(values) && return NaN
    ordered = sort(copy(values))
    midpoint = length(ordered) ÷ 2
    return isodd(length(ordered)) ? ordered[midpoint + 1] :
           (ordered[midpoint] + ordered[midpoint + 1]) / 2
end

function construct_origin_universes(config, paths; progress_callback = nothing)
    intervals = _load_security_intervals(paths.security_history, config)
    origins = origin_rows()
    reference_permnos = _reference_permnos(intervals, origins, config)
    decisions = _decision_dates(
        paths.daily_files,
        origins,
        reference_permnos,
        config;
        progress_callback,
    )
    interval_maps = Dict(
        origin.origin_id => _origin_interval_rows(intervals, decisions[origin.origin_id], config)
        for origin in origins
    )
    memberships = Dict{Int,Vector{NamedTuple}}()
    stats = Dict{Tuple{String,Int},UniverseStats}()
    for origin in origins
        compression_start = "$(origin.compression_start_year)-01-01"
        decision = decisions[origin.origin_id]
        for permno in keys(interval_maps[origin.origin_id])
            push!(get!(memberships, permno, NamedTuple[]), (
                origin_id = origin.origin_id,
                compression_start,
                decision,
            ))
            stats[(origin.origin_id, permno)] = UniverseStats()
        end
    end
    required = String.(config["source"]["required_daily_columns"]["columns"])
    last_date = Dict{Int,String}()
    source_rows_scanned = 0
    file_count = length(paths.daily_files)
    for (file_index, path) in enumerate(paths.daily_files)
        _report_scan(
            progress_callback,
            "universe-liquidity scan",
            "file-started",
            file_index,
            file_count,
            source_rows_scanned,
        )
        _with_daily_file(path) do io
            header = strip.(_split_csv(chomp(readline(io))))
            positions = _positions(header, required)
            for line in eachline(io)
                source_rows_scanned += 1
                source_rows_scanned % 1_000_000 == 0 && _report_scan(
                    progress_callback,
                    "universe-liquidity scan",
                    "running",
                    file_index,
                    file_count,
                    source_rows_scanned,
                )
                fields = _split_csv(chomp(line))
                length(fields) == length(header) || error("daily-security CSV width mismatch")
                permno = tryparse(Int, strip(fields[positions["permno"]]))
                isnothing(permno) && continue
                origin_memberships = get(memberships, permno, NamedTuple[])
                isempty(origin_memberships) && continue
                date = strip(fields[positions["dlycaldt"]])
                previous = get(last_date, permno, "")
                date > previous || error("duplicate or unstable daily ordering for a candidate PERMNO")
                last_date[permno] = date
                for membership in origin_memberships
                    date <= membership.decision || continue
                    entry = stats[(membership.origin_id, permno)]
                    entry.daily_rows += 1
                    membership.compression_start <= date || continue
                    entry.compression_rows += 1
                    close = _positive_close(fields, positions)
                    volume = _parse_float(fields[positions["dlyvol"]])
                    if isnothing(close) || isnothing(volume) || volume < 0
                        entry.invalid_liquidity_rows += 1
                    else
                        push!(entry.closes, close)
                        push!(entry.dollar_volumes, close * volume)
                    end
                end
            end
        end
        _report_scan(
            progress_callback,
            "universe-liquidity scan",
            "file-completed",
            file_index,
            file_count,
            source_rows_scanned,
        )
    end

    universe = config["universe"]
    keywords = uppercase.(String.(universe["exclude_name_keywords"]))
    result = OriginUniverse[]
    for origin in origins
        interval_map = interval_maps[origin.origin_id]
        eligible = NamedTuple[]
        for (permno, interval) in interval_map
            entry = stats[(origin.origin_id, permno)]
            name = uppercase(interval.security_name)
            excluded_keyword = something(
                findfirst(keyword -> occursin(keyword, name), keywords),
                0,
            )
            median_close = _median(entry.closes)
            median_dollar_volume = _median(entry.dollar_volumes)
            reasons = String[]
            entry.daily_rows < Int(universe["minimum_preorigin_daily_observations"]) &&
                push!(reasons, "insufficient_preorigin_daily_rows")
            length(entry.dollar_volumes) < Int(universe["minimum_compression_window_liquidity_observations"]) &&
                push!(reasons, "insufficient_compression_liquidity_rows")
            (!isfinite(median_close) || median_close < Float64(universe["minimum_median_close"])) &&
                push!(reasons, "price_floor")
            (!isfinite(median_dollar_volume) || median_dollar_volume < Float64(universe["minimum_median_dollar_volume"])) &&
                push!(reasons, "dollar_volume_floor")
            excluded_keyword > 0 && push!(reasons, "complex_product_keyword")
            isempty(reasons) || continue
            push!(eligible, (
                permno,
                ticker = interval.ticker,
                security_name_sha256 = _sha256_text(interval.security_name),
                median_close,
                median_dollar_volume,
                preorigin_daily_rows = entry.daily_rows,
                compression_liquidity_rows = length(entry.dollar_volumes),
                invalid_liquidity_rows = entry.invalid_liquidity_rows,
            ))
        end
        sort!(eligible; by = row -> (-row.median_dollar_volume, row.permno))
        cap = Int(universe["maximum_eligible_by_liquidity"])
        selected = collect(first(eligible, min(cap, length(eligible))))
        length(selected) >= Int(universe["minimum_eligible_for_analysis"]) || error(
            "$(origin.origin_id) has fewer than the registered minimum eligible securities",
        )
        reference_permno = reference_permnos[origin.origin_id]
        any(row -> row.permno == reference_permno, selected) || error(
            "$(origin.origin_id) does not retain the registered SPY reference",
        )
        push!(result, OriginUniverse(
            origin.origin_id,
            origin.decision_year,
            decisions[origin.origin_id],
            "$(origin.construction_start_year)-01-01",
            "$(origin.construction_end_year)-12-31",
            "$(origin.compression_start_year)-01-01",
            decisions[origin.origin_id],
            "$(origin.postdecision_year)-01-01",
            "$(origin.postdecision_year)-12-31",
            selected,
            length(interval_map),
            length(eligible),
            reference_permno,
        ))
    end
    sort!(result; by = origin -> origin.origin_id)
    return result
end

function extract_daily_series(config, daily_files, permnos; end_date::AbstractString)
    targets = Set(Int.(collect(permnos)))
    observations = Dict{Int,Vector{DailyObservation}}(permno => DailyObservation[] for permno in targets)
    required = String.(config["source"]["required_daily_columns"]["columns"])
    last_date = Dict{Int,String}()
    for path in daily_files
        _with_daily_file(path) do io
            header = strip.(_split_csv(chomp(readline(io))))
            positions = _positions(header, required)
            for line in eachline(io)
                fields = _split_csv(chomp(line))
                length(fields) == length(header) || error("daily-security CSV width mismatch")
                permno = tryparse(Int, strip(fields[positions["permno"]]))
                isnothing(permno) && continue
                permno in targets || continue
                date = strip(fields[positions["dlycaldt"]])
                date <= end_date || continue
                previous = get(last_date, permno, "")
                date > previous || error("duplicate or unstable daily ordering for a selected PERMNO")
                total_return = _parse_float(fields[positions["dlyret"]])
                isnothing(total_return) && error("selected daily return is missing or nonnumeric")
                total_return > -1 || error("selected daily return is not compoundable")
                close = _positive_close(fields, positions)
                isnothing(close) && error("selected close and price fallback are invalid")
                volume = _parse_float(fields[positions["dlyvol"]])
                (isnothing(volume) || volume < 0) && error("selected daily volume is invalid")
                push!(observations[permno], DailyObservation(
                    date,
                    total_return,
                    close,
                    volume,
                    strip(fields[positions["dlydelflg"]]),
                    strip(fields[positions["dlyretmissflg"]]),
                ))
                last_date[permno] = date
            end
        end
    end
    all(!isempty, values(observations)) || error("a selected PERMNO has no daily series")
    return observations
end

"""
    extract_origin_series(config, daily_files, origins; phase)

Read returns into origin-scoped maps. Structural maps end at the registered
compression date; postdecision maps contain only the one-year warm-up and the
registered postdecision year. A strategy builder therefore never receives a
different origin's future observations merely because all origins share one
physical CRSP delivery.
"""
function extract_origin_series(
    config,
    daily_files,
    origins;
    phase::Symbol,
    diagnostics::Union{Nothing,AbstractDict} = nothing,
    progress_callback = nothing,
)
    phase in (:structural, :postdecision) ||
        throw(ArgumentError("origin-series phase must be structural or postdecision"))
    contexts = Dict{Int,Vector{NamedTuple}}()
    observations = Dict{String,Dict{Int,Vector{DailyObservation}}}()
    quality = Dict{String,Dict{String,Int}}()
    for origin in origins
        selected = Set([origin.reference_permno; Int[row.permno for row in origin.selected]])
        start_year = phase == :structural ?
            parse(Int, first(split(origin.construction_start, '-'))) - 1 :
            parse(Int, first(split(origin.postdecision_start, '-'))) - 1
        window_start = "$(start_year)-01-01"
        window_end = phase == :structural ? origin.compression_end : origin.postdecision_end
        observations[origin.origin_id] = Dict(
            permno => DailyObservation[] for permno in selected
        )
        quality[origin.origin_id] = Dict(
            "origin_security_series" => length(selected),
            "source_rows_seen" => 0,
            "valid_return_rows_retained" => 0,
            "new_security_initialization_rows_excluded" => 0,
            "interior_missing_return_rows" => 0,
            "unexpected_return_flag_rows" => 0,
        )
        for permno in selected
            push!(get!(contexts, permno, NamedTuple[]), (
                origin_id = origin.origin_id,
                window_start,
                window_end,
            ))
        end
    end
    required = String.(config["source"]["required_daily_columns"]["columns"])
    last_source_date = Dict{Tuple{String,Int},String}()
    source_rows_scanned = 0
    file_count = length(daily_files)
    scan_stage = phase == :structural ? "structural-return scan" : "postdecision-return scan"
    for (file_index, path) in enumerate(daily_files)
        _report_scan(
            progress_callback,
            scan_stage,
            "file-started",
            file_index,
            file_count,
            source_rows_scanned,
        )
        _with_daily_file(path) do io
            header = strip.(_split_csv(chomp(readline(io))))
            positions = _positions(header, required)
            for line in eachline(io)
                source_rows_scanned += 1
                source_rows_scanned % 1_000_000 == 0 && _report_scan(
                    progress_callback,
                    scan_stage,
                    "running",
                    file_index,
                    file_count,
                    source_rows_scanned,
                )
                fields = _split_csv(chomp(line))
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
                total_return = _parse_float(fields[positions["dlyret"]])
                return_flag = strip(fields[positions["dlyretmissflg"]])
                first_source_row = Dict{String,Bool}()
                for context in matching
                    key = (context.origin_id, permno)
                    first_source_row[context.origin_id] = !haskey(last_source_date, key)
                    date > get(last_source_date, key, "") ||
                        error("duplicate or unstable daily ordering for an origin-scoped PERMNO")
                    last_source_date[key] = date
                    quality[context.origin_id]["source_rows_seen"] += 1
                end
                if isnothing(total_return)
                    for context in matching
                        if first_source_row[context.origin_id] && return_flag == "NS"
                            quality[context.origin_id]["new_security_initialization_rows_excluded"] += 1
                        else
                            first_source_row[context.origin_id] ||
                                (quality[context.origin_id]["interior_missing_return_rows"] += 1)
                            return_flag == "NS" ||
                                (quality[context.origin_id]["unexpected_return_flag_rows"] += 1)
                            error(
                                "selected daily return violates the locked missing-return rule; " *
                                "only a first-row CRSP NS initialization may be excluded",
                            )
                        end
                    end
                    continue
                end
                total_return > -1 || error("selected daily return is not compoundable")
                return_flag == "NA" || begin
                    for context in matching
                        quality[context.origin_id]["unexpected_return_flag_rows"] += 1
                    end
                    error("a finite selected daily return does not carry CRSP flag NA")
                end
                close = _positive_close(fields, positions)
                isnothing(close) && error("selected close and price fallback are invalid")
                volume = _parse_float(fields[positions["dlyvol"]])
                (isnothing(volume) || volume < 0) && error("selected daily volume is invalid")
                observation = DailyObservation(
                    date,
                    total_return,
                    close,
                    volume,
                    strip(fields[positions["dlydelflg"]]),
                    return_flag,
                )
                for context in matching
                    push!(observations[context.origin_id][permno], observation)
                    quality[context.origin_id]["valid_return_rows_retained"] += 1
                end
            end
        end
        _report_scan(
            progress_callback,
            scan_stage,
            "file-completed",
            file_index,
            file_count,
            source_rows_scanned,
        )
    end
    for (origin_id, series) in observations
        all(!isempty, values(series)) ||
            error("an origin-scoped selected PERMNO has no $phase daily series: $origin_id")
        row = quality[origin_id]
        row["source_rows_seen"] ==
        row["valid_return_rows_retained"] +
        row["new_security_initialization_rows_excluded"] ||
            error("origin-scoped return-quality counts do not reconcile")
        row["interior_missing_return_rows"] == 0 ||
            error("origin-scoped extraction contains an interior missing return")
        row["unexpected_return_flag_rows"] == 0 ||
            error("origin-scoped extraction contains an unexpected return flag")
    end
    if !isnothing(diagnostics)
        empty!(diagnostics)
        merge!(diagnostics, quality)
    end
    return observations
end

function _empirical_quantile(values::Vector{Float64}, probability::Float64)
    isempty(values) && error("cannot compute an empirical quantile from no observations")
    0 <= probability <= 1 || error("quantile probability must lie in [0,1]")
    ordered = sort(copy(values))
    return ordered[clamp(ceil(Int, probability * length(ordered)), 1, length(ordered))]
end

function _mean(values)
    isempty(values) && return NaN
    return sum(Float64, values) / length(values)
end

function _variance(values)
    length(values) <= 1 && return 0.0
    average = _mean(values)
    return sum(value -> (Float64(value) - average)^2, values) / (length(values) - 1)
end

function _utility(values, config)
    isempty(values) && return NaN
    settings = config["operating_profiles"]
    annualization = Float64(settings["annualization_sessions"])
    risk_aversion = Float64(settings["risk_aversion"])
    return annualization * _mean(values) -
           0.5 * risk_aversion * annualization * _variance(values)
end

function _total_return_index(observations)
    values = fill(100.0, length(observations))
    for index in 2:length(observations)
        values[index] = values[index - 1] * (1 + observations[index].total_return)
        isfinite(values[index]) && values[index] > 0 || error("invalid compounded return index")
    end
    return values
end

function _lookback_return(prices, index::Int, lookback::Int)
    index > lookback || return NaN
    return prices[index] / prices[index - lookback] - 1
end

function _rolling_mean(values, index::Int, lookback::Int)
    index >= lookback || return NaN
    return _mean(@view values[(index - lookback + 1):index])
end

function _rolling_volatility(returns, index::Int, lookback::Int, annualization::Int)
    index > lookback || return NaN
    return sqrt(annualization * _variance(@view returns[(index - lookback + 1):index]))
end

function _canonical_specification(
    origin_id,
    permno,
    signal,
    filter,
    horizon,
    sizing,
    exit_rule,
    risk,
)
    return join((
        "schema=financial-panel-strategy-spec-v1",
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

function _panel_strategy(origin_id, permno, signal, filter, horizon, sizing, exit_rule, risk)
    capabilities = capability_ids_for_spec(
        signal = signal,
        filter = filter,
        horizon = horizon,
        sizing = sizing,
        exit_rule = exit_rule,
        risk = risk,
    )
    canonical = _canonical_specification(
        origin_id,
        permno,
        signal,
        filter,
        horizon,
        sizing,
        exit_rule,
        risk,
    )
    return PanelStrategy(
        String(origin_id),
        Int(permno),
        String(signal),
        String(filter),
        Int(horizon),
        String(sizing),
        String(exit_rule),
        String(risk),
        Tuple(capabilities),
        _sha256_text(canonical),
    )
end

function _strategy_key(strategy::PanelStrategy)
    return (
        strategy.permno,
        strategy.directional_signal,
        strategy.entry_filter,
        strategy.holding_horizon,
        strategy.sizing_rule,
        strategy.exit_rule,
        strategy.risk_constraint,
    )
end

function _strategy_id(strategy::PanelStrategy, library_id::AbstractString)
    return join((
        strategy.origin_id,
        library_id,
        strategy.permno,
        strategy.directional_signal,
        strategy.entry_filter,
        strategy.holding_horizon,
        strategy.sizing_rule,
        strategy.exit_rule,
        strategy.risk_constraint,
    ), '|')
end

function _catalog(origin::OriginUniverse, config)
    grammar = config["grammar"]
    catalog = PanelStrategy[]
    for security in origin.selected,
        signal in String.(grammar["directional_signal"]),
        filter in String.(grammar["entry_filter"]),
        horizon in Int.(grammar["holding_horizon"]),
        sizing in String.(grammar["sizing_rule"]),
        exit_rule in String.(grammar["exit_rule"]),
        risk in String.(grammar["risk_constraint"])
        push!(catalog, _panel_strategy(
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
    sort!(catalog; by = _strategy_key)
    expected = length(origin.selected) * Int(grammar["strategies_per_instrument_full_factorial"])
    length(catalog) == expected || error("factorial strategy catalog size mismatch")
    return catalog
end

function _backtest(strategy::PanelStrategy, observations, config, amendment)
    prices = _total_return_index(observations)
    returns = Float64[row.total_return for row in observations]
    intended = zeros(Float64, length(observations))
    position = 0.0
    age = 0
    annualization = Int(config["operating_profiles"]["annualization_sessions"])
    trend_lookback = Int(amendment["lookbacks"]["trend_filter_sessions"])
    volatility_lookback = Int(amendment["lookbacks"]["volatility_sessions"])
    for index in eachindex(observations)
        signal_value = if strategy.directional_signal == "momentum_20"
            value = _lookback_return(prices, index, 20)
            isfinite(value) && value > 0
        elseif strategy.directional_signal == "momentum_60"
            value = _lookback_return(prices, index, 60)
            isfinite(value) && value > 0
        elseif strategy.directional_signal == "mean_reversion_5"
            value = _lookback_return(prices, index, 5)
            isfinite(value) && value < 0
        else
            error("unsupported directional signal")
        end
        filter_passes = if strategy.entry_filter == "always"
            true
        elseif strategy.entry_filter == "trend_100"
            average = _rolling_mean(prices, index, trend_lookback)
            isfinite(average) && prices[index] > average
        else
            error("unsupported entry filter")
        end
        base_size = strategy.sizing_rule == "unit" ? 1.0 :
                    strategy.sizing_rule == "half" ? 0.5 :
                    error("unsupported sizing rule")
        size = function()
            strategy.risk_constraint == "notional_cap_1" && return min(base_size, 1.0)
            strategy.risk_constraint == "vol_target_10" || error("unsupported risk constraint")
            volatility = _rolling_volatility(
                returns,
                index,
                volatility_lookback,
                annualization,
            )
            return !isfinite(volatility) || volatility <= 0 ? 0.0 :
                   min(base_size, 0.10 / volatility)
        end
        if iszero(position)
            if signal_value && filter_passes
                position = size()
                age = position > 0 ? 1 : 0
            end
        else
            should_exit = age >= strategy.holding_horizon ||
                          (strategy.exit_rule == "signal_flip" && !signal_value)
            if should_exit
                position = 0.0
                age = 0
            else
                position = size()
                age += 1
            end
        end
        intended[index] = position
    end
    lag = Int(config["operating_profiles"]["decision_to_first_return_lag_sessions"])
    effective = zeros(Float64, length(observations))
    for index in (lag + 1):length(observations)
        effective[index] = intended[index - lag]
    end
    turnover = similar(effective)
    turnover[1] = abs(effective[1])
    for index in 2:length(effective)
        turnover[index] = abs(effective[index] - effective[index - 1])
    end
    cost = Float64(config["operating_profiles"]["one_way_transaction_cost_bps"]) / 10_000
    net = effective .* returns .- cost .* turnover
    return (net = net, turnover = turnover, position = effective)
end

function _belief_states(origin::OriginUniverse, reference_rows, config, amendment)
    observations = [row for row in reference_rows if row.date <= origin.compression_end]
    prices = _total_return_index(observations)
    lookback = Int(amendment["lookbacks"]["belief_sessions"])
    features = [_lookback_return(prices, index, lookback) for index in eachindex(prices)]
    construction = Float64[
        features[index] for index in eachindex(features) if
        origin.construction_start <= observations[index].date <= origin.construction_end &&
        isfinite(features[index])
    ]
    probabilities = Float64.(config["operating_profiles"]["belief_cutpoints"])
    thresholds = [_empirical_quantile(construction, probability) for probability in probabilities]
    issorted(thresholds) || error("belief thresholds are not ordered")
    state_by_date = Dict{String,Int}()
    for index in eachindex(features)
        isfinite(features[index]) || continue
        state_by_date[observations[index].date] = searchsortedfirst(thresholds, features[index])
    end
    return thresholds, state_by_date
end

function _profile(net, dates, state_by_date, start_date, end_date, config)
    state_count = Int(config["operating_profiles"]["belief_state_count"])
    minimum = Int(config["operating_profiles"]["minimum_profile_observations"])
    result = Float64[]
    for state in 1:state_count
        values = Float64[
            net[index] for index in eachindex(dates) if
            start_date <= dates[index] <= end_date &&
            get(state_by_date, dates[index], 0) == state
        ]
        length(values) >= minimum || error("a registered belief profile has too few observations")
        push!(result, _utility(values, config))
    end
    return result
end

function _evaluation(strategy, rows, state_by_date, origin, config, amendment)
    observations = [row for row in rows if row.date <= origin.compression_end]
    dates = getfield.(observations, :date)
    backtest = _backtest(strategy, observations, config, amendment)
    construction_indices = findall(
        date -> origin.construction_start <= date <= origin.construction_end,
        dates,
    )
    isempty(construction_indices) && error("construction window is empty")
    compression_sessions = count(
        date -> origin.compression_start <= date <= origin.compression_end,
        dates,
    )
    compression_sessions > 0 || error("compression window is empty")
    decisions = cld(compression_sessions, strategy.holding_horizon)
    work_units = validation_work_units(
        signal_evaluations = compression_sessions,
        filter_evaluations = strategy.entry_filter == "always" ? 0 : compression_sessions,
        risk_updates = strategy.risk_constraint == "notional_cap_1" ? 0 : compression_sessions,
        position_decisions = decisions,
        exit_evaluations = strategy.exit_rule == "horizon" ? decisions : compression_sessions,
    )
    baseline = (
        "momentum_20",
        "always",
        5,
        "unit",
        "horizon",
        "notional_cap_1",
    )
    actual = (
        strategy.directional_signal,
        strategy.entry_filter,
        strategy.holding_horizon,
        strategy.sizing_rule,
        strategy.exit_rule,
        strategy.risk_constraint,
    )
    nonbaseline = count(index -> actual[index] != baseline[index], eachindex(actual))
    return StrategyEvaluation(
        strategy,
        _utility(backtest.net[construction_indices], config),
        _profile(
            backtest.net,
            dates,
            state_by_date,
            origin.construction_start,
            origin.construction_end,
            config,
        ),
        _profile(
            backtest.net,
            dates,
            state_by_date,
            origin.compression_start,
            origin.compression_end,
            config,
        ),
        compression_sessions,
        work_units,
        governance_review_units(nonbaseline),
    )
end

function _add_capability_completion!(selected, evaluations)
    registered = sort!(String[row.capability_id for row in capability_rows()])
    carried = Set{String}()
    for evaluation in values(selected)
        union!(carried, evaluation.strategy.capability_ids)
    end
    for capability in registered
        capability in carried && continue
        carriers = [
            evaluation for evaluation in evaluations if
            capability in evaluation.strategy.capability_ids
        ]
        isempty(carriers) && error("registered capability has no factorial carrier")
        best = maximum(item.construction_score for item in carriers)
        for carrier in carriers
            carrier.construction_score == best || continue
            selected[_strategy_key(carrier.strategy)] = carrier
            union!(carried, carrier.strategy.capability_ids)
        end
    end
    Set(registered) == carried || error("capability completion failed")
    return selected
end

function _library(evaluations, library_id::AbstractString, origin::OriginUniverse)
    selected = Dict{Any,StrategyEvaluation}()
    if library_id == "full_factorial_catalog"
        for evaluation in evaluations
            selected[_strategy_key(evaluation.strategy)] = evaluation
        end
    elseif library_id == "decentralized_signal_sleeves"
        groups = Dict{Tuple{Int,String},Vector{StrategyEvaluation}}()
        for evaluation in evaluations
            key = (evaluation.strategy.permno, evaluation.strategy.directional_signal)
            push!(get!(groups, key, StrategyEvaluation[]), evaluation)
        end
        for group in values(groups)
            sort!(group; by = item -> (-item.construction_score, _strategy_key(item.strategy)))
            cutoff = group[min(2, length(group))].construction_score
            for item in group
                item.construction_score >= cutoff || continue
                selected[_strategy_key(item.strategy)] = item
            end
        end
        _add_capability_completion!(selected, evaluations)
    elseif library_id == "centralized_research_pool"
        ordered = sort(copy(evaluations); by = item -> (-item.construction_score, _strategy_key(item.strategy)))
        count_target = 2 * length(origin.selected)
        cutoff = ordered[min(count_target, length(ordered))].construction_score
        for item in ordered
            item.construction_score >= cutoff || continue
            selected[_strategy_key(item.strategy)] = item
        end
        state_count = length(first(evaluations).construction_profile)
        for state in 1:state_count
            frontier = maximum(item.construction_profile[state] for item in evaluations)
            for item in evaluations
                item.construction_profile[state] == frontier || continue
                selected[_strategy_key(item.strategy)] = item
            end
        end
        _add_capability_completion!(selected, evaluations)
    else
        error("unsupported source-library construction: $library_id")
    end
    result = sort!(collect(values(selected)); by = item -> _strategy_key(item.strategy))
    isempty(result) && error("source-library construction returned no strategies")
    return result
end

function _instance(
    source,
    origin,
    library_id,
    schedule_id,
    thresholds,
)
    ids = Any["inactive"]
    append!(ids, _strategy_id(item.strategy, library_id) for item in source)
    profiles = Matrix{ExactRational}(undef, length(ids), 5)
    profiles[1, :] .= zero(ExactRational)
    modules = Vector{Vector{Any}}(undef, length(ids))
    modules[1] = Any[]
    weights = Any[0]
    spec_hashes = String[]
    for (position, item) in enumerate(source)
        profiles[position + 1, :] .= _float_exact.(item.compression_profile)
        modules[position + 1] = Any[item.strategy.capability_ids...]
        weight = schedule_id == "validation_work_units" ? item.validation_work_units :
                 schedule_id == "equal_active_strategy" ? 1 :
                 schedule_id == "governance_review_units" ? item.governance_review_units :
                 error("unsupported burden schedule: $schedule_id")
        push!(weights, weight)
        push!(spec_hashes, item.strategy.specification_sha256)
    end
    provenance = JournalCompressionProvenance(
        :financial,
        "$(origin.origin_id):$library_id:$schedule_id",
        "point-in-time origin-eligible financial strategy-library panel v1";
        parent_hashes = [
            "source_specification_set_sha256" => _sha256_text(join(sort(spec_hashes), '\n')),
            "belief_thresholds_sha256" => _sha256_text(join(string.(thresholds), '\n')),
        ],
        attributes = [
            "origin_id" => origin.origin_id,
            "library_id" => String(library_id),
            "schedule_id" => String(schedule_id),
            "licensed_rows_included" => "false",
            "profile_evidence" => "floating-point predecision financial computation losslessly frozen to rationals",
        ],
        redistributable = true,
    )
    instance = journal_compression_instance_from_components(
        ids,
        Bool[true; falses(length(source))],
        weights,
        ["financial_state:$state" for state in 1:5],
        profiles,
        modules;
        tie_handling = JournalTieHandling(
            :declared_representative;
            declaration = "one deterministic optimizer identity unless an exact method records complete ties",
            stable_selector = "canonical origin, library, PERMNO, and grammar order",
        ),
        provenance,
    )
    validate_journal_compression_instance(instance)
    return instance
end

function build_origin_instances(origin::OriginUniverse, series, config, amendment)
    haskey(series, origin.reference_permno) || error("origin reference series is absent")
    thresholds, state_by_date = _belief_states(
        origin,
        series[origin.reference_permno],
        config,
        amendment,
    )
    evaluations = StrategyEvaluation[]
    for strategy in _catalog(origin, config)
        haskey(series, strategy.permno) || error("selected strategy series is absent")
        push!(evaluations, _evaluation(
            strategy,
            series[strategy.permno],
            state_by_date,
            origin,
            config,
            amendment,
        ))
    end
    instances = Dict{Tuple{String,String},JournalCompressionInstance}()
    source_counts = Dict{String,Int}()
    for library in library_rows()
        source = _library(evaluations, library.library_id, origin)
        source_counts[library.library_id] = length(source)
        for schedule_id in SCHEDULE_IDS
            instances[(library.library_id, schedule_id)] = _instance(
                source,
                origin,
                library.library_id,
                schedule_id,
                thresholds,
            )
        end
    end
    metadata = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-origin-build-v1",
        "origin_id" => origin.origin_id,
        "decision_year" => origin.decision_year,
        "decision_date" => origin.decision_date,
        "candidate_security_count" => origin.candidate_count,
        "eligible_security_count" => origin.eligible_count,
        "selected_security_count" => length(origin.selected),
        "reference_permno" => origin.reference_permno,
        "belief_thresholds" => thresholds,
        "source_strategy_counts" => source_counts,
        "licensed_rows_included" => false,
        "study_outcome" => false,
    )
    return instances, metadata
end

function _selection_payload(instance, selected)
    check = check_journal_compression_solution(instance, selected)
    indices = findall(selected)
    return Dict{String,Any}(
        "selected_strategy_indices" => indices,
        "selected_strategy_ids" => [string(instance.strategy_ids[index].id) for index in indices],
        "selected_strategy_count" => length(indices),
        "selected_active_strategy_count" => count(index -> !instance.mandatory[index], indices),
        "exact_burden" => _exact_text(check.exact_burden),
        "exact_mandatory_retention" => check.mandatory_retained,
        "exact_tagged_coverage" => check.tagged_coverage,
        "exact_frontier_preservation" => check.frontier_preserved,
        "exact_closure_preservation" => check.closure_preserved,
        "exact_feasible" => check.exact_feasible,
    )
end

function _base_algorithm_record(algorithm_id, applicable, status, elapsed_ns)
    return Dict{String,Any}(
        "algorithm_id" => String(algorithm_id),
        "applicable" => applicable,
        "status" => String(status),
        "terminal" => true,
        "wall_clock_ns" => string(elapsed_ns),
        "candidate_returned" => false,
        "solver_claimed_optimal" => false,
        "solver_status_used_as_exact_proof" => false,
        "termination_status" => "NOT_APPLICABLE",
        "primal_status" => "NOT_APPLICABLE",
        "dual_status" => "NOT_APPLICABLE",
        "objective_value" => Dict("available" => false),
        "best_bound" => Dict("available" => false),
        "reported_gap" => Dict("available" => false),
        "mip_node_count" => Dict("available" => false),
        "dp_state_count" => Dict("available" => false),
        "dp_transition_count" => Dict("available" => false),
        "enumerated_candidate_count" => Dict("available" => false),
        "frontier_checks" => Dict("available" => false),
        "closure_checks" => Dict("available" => false),
        "complete_scans" => Dict("available" => false),
        "random_seed" => Dict("available" => false),
        "multistart_count" => Dict("available" => false),
    )
end

_available(value) = Dict{String,Any}("available" => true, "value" => value)

function _panel_deletion_pass(instance, order)
    instance.identity_closure || error("carrier-count deletion requires identity closure")
    selected = trues(length(instance.strategy_ids))
    carrier_counts = Int[
        count(instance.coverage[row, :]) for row in axes(instance.coverage, 1)
    ]
    deletion_trace = Int[]
    tagged_safety_checks = 0
    for index in order
        instance.mandatory[index] && continue
        tagged_safety_checks += 1
        safe = true
        for row in axes(instance.coverage, 1)
            if instance.coverage[row, index] && carrier_counts[row] <= 1
                safe = false
                break
            end
        end
        safe || continue
        selected[index] = false
        push!(deletion_trace, index)
        for row in axes(instance.coverage, 1)
            instance.coverage[row, index] && (carrier_counts[row] -= 1)
        end
    end
    final_scan_checks = 0
    for index in eachindex(selected)
        selected[index] && !instance.mandatory[index] || continue
        final_scan_checks += 1
        any(
            instance.coverage[row, index] && carrier_counts[row] == 1 for
            row in axes(instance.coverage, 1)
        ) || error("carrier-count deletion endpoint is not inclusion-wise irreducible")
    end
    certificate = check_journal_compression_solution(instance, selected)
    certificate.exact_feasible ||
        error("carrier-count deletion endpoint failed independent semantic certification")
    return (
        selected,
        deletion_trace,
        tagged_safety_checks,
        final_scan_checks,
        exact_burden = certificate.exact_burden,
    )
end

function _panel_deletion(instance, algorithm_id, seed, starts)
    optional = Int[
        index for index in eachindex(instance.strategy_ids) if !instance.mandatory[index]
    ]
    if algorithm_id == "heaviest_safe_first"
        order = sort(optional; by = index -> (-instance.weights[index], index))
        result = _panel_deletion_pass(instance, order)
        return merge(result, (starts = 1, first_start_burden = result.exact_burden))
    elseif algorithm_id == "declared_source_order"
        result = _panel_deletion_pass(instance, optional)
        return merge(result, (starts = 1, first_start_burden = result.exact_burden))
    elseif algorithm_id == "multistart_random_rechecked_deletion_32"
        starts > 0 || error("multi-start deletion requires a positive start count")
        seed_rng = StableRNG(UInt64(seed))
        run_seeds = UInt64[UInt64(seed)]
        for _ in 2:starts
            push!(run_seeds, rand(seed_rng, UInt64))
        end
        results = [
            _panel_deletion_pass(
                instance,
                optional[randperm(StableRNG(run_seed), length(optional))],
            ) for run_seed in run_seeds
        ]
        best = first(results)
        for candidate in Iterators.drop(results, 1)
            candidate_indices = Tuple(findall(candidate.selected))
            best_indices = Tuple(findall(best.selected))
            if candidate.exact_burden < best.exact_burden ||
               (candidate.exact_burden == best.exact_burden && isless(candidate_indices, best_indices))
                best = candidate
            end
        end
        return merge(best, (
            starts = starts,
            first_start_burden = first(results).exact_burden,
            tagged_safety_checks = sum(result.tagged_safety_checks for result in results),
            final_scan_checks = sum(result.final_scan_checks for result in results),
        ))
    end
    error("unsupported panel deletion algorithm: $algorithm_id")
end

function _run_one_algorithm(
    instance,
    algorithm_id,
    controls,
    greedy_cache,
    preprocessing,
    preprocessed_instance,
)
    start = time_ns()
    logs = Dict{String,String}()
    try
        if algorithm_id == "weighted_greedy_reverse_delete"
            result = solve_journal_compression_weighted_greedy_reverse_delete(instance)
            record = _base_algorithm_record(
                algorithm_id,
                true,
                string(result.status),
                time_ns() - start,
            )
            record["candidate_returned"] = true
            record["selection"] = _selection_payload(instance, result.selected)
            record["greedy_step_count"] = length(result.step_trace)
            record["reverse_deletion_count"] = length(result.reverse_deletion_trace)
            return record, logs, result.selected
        elseif algorithm_id == "heaviest_safe_first"
            result = _panel_deletion(instance, algorithm_id, controls.multistart_seed, 1)
            record = _base_algorithm_record(
                algorithm_id,
                true,
                "CERTIFIED_IRREDUCIBLE_HEURISTIC",
                time_ns() - start,
            )
            record["candidate_returned"] = true
            record["selection"] = _selection_payload(instance, result.selected)
            record["tagged_safety_checks"] = _available(result.tagged_safety_checks)
            record["frontier_checks"] = _available(1)
            record["closure_checks"] = _available(1)
            record["complete_scans"] = _available(1)
            record["deletion_count"] = length(result.deletion_trace)
            record["deletion_update_method"] = "exact identity-closure carrier counts"
            return record, logs, result.selected
        elseif algorithm_id == "declared_source_order"
            result = _panel_deletion(instance, algorithm_id, controls.multistart_seed, 1)
            record = _base_algorithm_record(
                algorithm_id,
                true,
                "CERTIFIED_IRREDUCIBLE_HEURISTIC",
                time_ns() - start,
            )
            record["candidate_returned"] = true
            record["selection"] = _selection_payload(instance, result.selected)
            record["tagged_safety_checks"] = _available(result.tagged_safety_checks)
            record["frontier_checks"] = _available(1)
            record["closure_checks"] = _available(1)
            record["complete_scans"] = _available(1)
            record["deletion_count"] = length(result.deletion_trace)
            record["deletion_update_method"] = "exact identity-closure carrier counts"
            return record, logs, result.selected
        elseif algorithm_id == "multistart_random_rechecked_deletion_32"
            result = _panel_deletion(
                instance,
                algorithm_id,
                controls.multistart_seed,
                controls.multistart_count,
            )
            record = _base_algorithm_record(
                algorithm_id,
                true,
                "CERTIFIED_IRREDUCIBLE_HEURISTIC",
                time_ns() - start,
            )
            record["candidate_returned"] = true
            record["selection"] = _selection_payload(instance, result.selected)
            record["tagged_safety_checks"] = _available(result.tagged_safety_checks)
            record["frontier_checks"] = _available(result.starts)
            record["closure_checks"] = _available(result.starts)
            record["complete_scans"] = _available(result.starts)
            record["deletion_count"] = length(result.deletion_trace)
            record["first_start_burden"] = _exact_text(result.first_start_burden)
            record["multi_start_improvement"] =
                _exact_text(result.first_start_burden - result.exact_burden)
            record["deletion_update_method"] = "exact identity-closure carrier counts"
            record["random_seed"] = _available(string(controls.multistart_seed))
            record["multistart_count"] = _available(controls.multistart_count)
            return record, logs, result.selected
        end

        residual_requirements = length(preprocessing.reduced.requirements)
        residual_strategies = length(preprocessing.reduced.strategy_ids)
        if algorithm_id == "requirement_mask_dp"
            if residual_requirements > controls.dp_requirement_limit
                record = _base_algorithm_record(
                    algorithm_id,
                    false,
                    "SKIPPED_RESIDUAL_REQUIREMENT_LIMIT",
                    time_ns() - start,
                )
                record["residual_requirement_count"] = residual_requirements
                return record, logs, nothing
            end
            result = solve_journal_compression_dp(
                preprocessed_instance;
                retain_all_ties = false,
            )
            record = _base_algorithm_record(algorithm_id, true, string(result.status), time_ns() - start)
            record["candidate_returned"] = true
            record["selection"] = _selection_payload(instance, result.selected)
            record["dp_state_count"] = _available(string(result.counters.state_layer_pairs_visited))
            record["dp_transition_count"] = _available(string(result.counters.transitions_evaluated))
            return record, logs, result.selected
        elseif algorithm_id == "complete_enumeration"
            if residual_strategies > controls.enumeration_strategy_limit
                record = _base_algorithm_record(
                    algorithm_id,
                    false,
                    "SKIPPED_RESIDUAL_STRATEGY_LIMIT",
                    time_ns() - start,
                )
                record["residual_strategy_count"] = residual_strategies
                return record, logs, nothing
            end
            result = solve_journal_compression_enumeration(
                preprocessed_instance;
                retain_all_ties = false,
                maximum_optional_strategies = controls.enumeration_strategy_limit,
            )
            record = _base_algorithm_record(algorithm_id, true, string(result.status), time_ns() - start)
            record["candidate_returned"] = true
            record["selection"] = _selection_payload(instance, result.selected)
            record["enumerated_candidate_count"] =
                _available(string(result.counters.candidate_selections_evaluated))
            return record, logs, result.selected
        elseif algorithm_id == "jump_highs_tagged_cover"
            warm_start = isnothing(greedy_cache) ? :none : greedy_cache
            result = solve_journal_compression_mip(
                instance;
                random_seed = controls.mip_seed,
                time_limit = controls.mip_time_limit_seconds,
                relative_mip_gap_tolerance = controls.mip_relative_gap,
                absolute_mip_gap_tolerance = controls.mip_absolute_gap,
                warm_start,
                warm_start_source = "registered weighted greedy plus reverse deletion",
                exact_crosscheck = :none,
                preprocessing_result = preprocessing,
            )
            record = _base_algorithm_record(algorithm_id, true, string(result.status), time_ns() - start)
            diagnostics = result.diagnostics
            record["termination_status"] = diagnostics.termination_status
            record["primal_status"] = diagnostics.primal_status
            record["dual_status"] = diagnostics.dual_status
            record["solver_name"] = diagnostics.solver_name
            record["solver_version"] = diagnostics.solver_version
            record["objective_value"] = ismissing(diagnostics.objective_value) ?
                Dict("available" => false) : _available(diagnostics.objective_value)
            record["best_bound"] = ismissing(diagnostics.best_bound) ?
                Dict("available" => false) : _available(diagnostics.best_bound)
            record["reported_gap"] = ismissing(diagnostics.reported_relative_gap) ?
                Dict("available" => false) : _available(diagnostics.reported_relative_gap)
            record["mip_node_count"] = ismissing(diagnostics.node_count) ?
                Dict("available" => false) : _available(diagnostics.node_count)
            record["solver_claimed_optimal"] = result.solver_claimed_optimal
            record["preprocessing_solved_empty_residual"] =
                result.preprocessing.reduced_strategy_count == 0 &&
                result.preprocessing.reduced_requirement_count == 0
            record["preprocessing_variables_removed"] = result.preprocessing.variables_removed
            record["preprocessing_requirements_removed"] = result.preprocessing.requirements_removed
            logs[algorithm_id] = diagnostics.complete_solver_log
            if !isnothing(result.reconstructed_candidate)
                record["candidate_returned"] = true
                record["selection"] = _selection_payload(instance, result.reconstructed_candidate)
                return record, logs, result.reconstructed_candidate
            end
            return record, logs, nothing
        end
        error("unknown registered algorithm: $algorithm_id")
    catch exception
        record = _base_algorithm_record(
            algorithm_id,
            true,
            "ERROR",
            time_ns() - start,
        )
        record["failure_type"] = string(typeof(exception))
        record["failure_message"] = sprint(showerror, exception)
        return record, logs, nothing
    end
end

function _structure(instance, preprocessing)
    preprocessing.feasible || error("source instance is infeasible")
    active = findall(.!instance.mandatory)
    frontier = count(requirement -> requirement isa FrontierRequirement, instance.requirements)
    modules = count(requirement -> requirement isa ModuleRequirement, instance.requirements)
    carriers = [count(instance.coverage[row, :]) for row in axes(instance.coverage, 1)]
    signatures = Dict{Tuple{Vararg{Bool}},Int}()
    for column in active
        signature = Tuple(instance.coverage[:, column])
        signatures[signature] = get(signatures, signature, 0) + 1
    end
    rule_counts = preprocessing.audit["rule_counts"]
    return Dict{String,Any}(
        "active_strategy_count" => length(active),
        "frontier_requirement_count" => frontier,
        "module_requirement_count" => modules,
        "tagged_requirement_count" => length(instance.requirements),
        "coverage_density" => isempty(active) || isempty(instance.requirements) ? "0//1" :
            _exact_text(BigInt(count(instance.coverage[:, active])) //
                        BigInt(length(active) * length(instance.requirements))),
        "duplicate_coverage_count" => sum(max(value - 1, 0) for value in values(signatures); init = 0),
        "unique_carrier_count" => count(==(1), carriers),
        "variables_before_preprocessing" => length(instance.strategy_ids),
        "variables_after_preprocessing" => length(preprocessing.reduced.strategy_ids),
        "requirements_before_preprocessing" => length(instance.requirements),
        "requirements_after_preprocessing" => length(preprocessing.reduced.requirements),
        "forced_strategy_count" => length(preprocessing.forced_strategy_indices),
        "dominance_reductions" => Int(rule_counts["coverage_dominance"]["variables_removed"]),
        "preprocessing_fixed_point_iterations" => Int(preprocessing.audit["fixed_point_iterations"]),
    )
end

function _seed_for(origin_id, library_id)
    matches = filter(
        item -> item.origin_id == origin_id && item.library_id == library_id,
        seed_rows(),
    )
    if isempty(matches) && startswith(origin_id, "SMOKE-O")
        return UInt64(10_000 + parse(Int, split(origin_id, 'O')[end]))
    end
    return UInt64(only(matches).multistart_seed)
end

function run_algorithm_suite(
    instance;
    origin_id,
    library_id,
    schedule_id,
    config,
    progress_callback = _ -> nothing,
    checkpoint_callback = (args...) -> nothing,
    resume_algorithms = Dict{String,Any}(),
    heavy_executor = function(task)
        task()
    end,
)
    controls = (
        dp_requirement_limit = Int(config["algorithms"]["dp_requirement_limit"]),
        enumeration_strategy_limit = Int(config["algorithms"]["enumeration_optional_strategy_limit"]),
        multistart_count = Int(config["algorithms"]["multistart_count"]),
        multistart_seed = _seed_for(origin_id, library_id),
        mip_seed = Int(config["algorithms"]["highs_random_seed"]),
        mip_time_limit_seconds = Float64(config["algorithms"]["highs_time_limit_seconds"]),
        mip_relative_gap = Float64(config["algorithms"]["highs_relative_gap"]),
        mip_absolute_gap = Float64(config["algorithms"]["highs_absolute_gap"]),
    )
    records = Dict{String,Any}[]
    logs = Dict{String,String}()
    selections = Dict{String,BitVector}()
    progress_callback((
        stage = "preprocessing",
        state = "started",
        algorithm_id = nothing,
    ))
    preprocessing = heavy_executor() do
        preprocess_tagged_cover(exact_tagged_cover_model(instance))
    end
    preprocessing.feasible || error("preprocessing declared the source infeasible")
    preprocessed_instance = apply_tagged_preprocessing(instance, preprocessing)
    progress_callback((
        stage = "preprocessing",
        state = "completed",
        algorithm_id = nothing,
        residual_requirements = length(preprocessing.reduced.requirements),
        residual_strategies = length(preprocessing.reduced.strategy_ids),
    ))
    heavy_algorithms = Set((
        "requirement_mask_dp",
        "complete_enumeration",
        "jump_highs_tagged_cover",
    ))
    run_or_resume = function(algorithm_id, warm_start)
        if haskey(resume_algorithms, algorithm_id)
            saved = resume_algorithms[algorithm_id]
            record = deepcopy(saved.record)
            selection = isnothing(saved.selection) ? nothing : copy(saved.selection)
            progress_callback((
                stage = "algorithm",
                state = "resumed",
                algorithm_id,
                status = record["status"],
            ))
            return record, Dict{String,String}(), selection
        end
        progress_callback((
            stage = "algorithm",
            state = "started",
            algorithm_id,
        ))
        task = () -> _run_one_algorithm(
            instance,
            algorithm_id,
            controls,
            warm_start,
            preprocessing,
            preprocessed_instance,
        )
        record, algorithm_logs, selection = algorithm_id in heavy_algorithms ?
                                            heavy_executor(task) : task()
        checkpoint_callback(
            algorithm_id,
            record,
            selection,
            algorithm_logs,
        )
        progress_callback((
            stage = "algorithm",
            state = "completed",
            algorithm_id,
            status = record["status"],
        ))
        return record, algorithm_logs, selection
    end
    greedy_record, greedy_logs, greedy_selection = run_or_resume(
        "weighted_greedy_reverse_delete",
        nothing,
    )
    push!(records, greedy_record)
    merge!(logs, greedy_logs)
    isnothing(greedy_selection) || (selections["weighted_greedy_reverse_delete"] = greedy_selection)
    for algorithm_id in ALGORITHM_IDS
        algorithm_id == "weighted_greedy_reverse_delete" && continue
        record, algorithm_logs, selection = run_or_resume(
            algorithm_id,
            greedy_selection,
        )
        push!(records, record)
        merge!(logs, algorithm_logs)
        isnothing(selection) || (selections[algorithm_id] = selection)
    end
    order = Dict(algorithm => index for (index, algorithm) in enumerate(ALGORITHM_IDS))
    sort!(records; by = record -> order[record["algorithm_id"]])

    exact_records = [
        record for record in records if
        record["algorithm_id"] in ("requirement_mask_dp", "complete_enumeration") &&
        record["candidate_returned"] === true
    ]
    exact_burdens = unique(record["selection"]["exact_burden"] for record in exact_records)
    length(exact_burdens) <= 1 || error("exact enumeration and DP burdens disagree")
    feasible_records = [record for record in records if record["candidate_returned"] === true &&
                        record["selection"]["exact_feasible"] === true]
    isempty(feasible_records) && error("no algorithm returned an exactly feasible endpoint")
    burden_pairs = [(exact_rational(record["selection"]["exact_burden"]), record) for record in feasible_records]
    best_feasible = minimum(pair -> first(pair), burden_pairs)
    benchmark_burden = isempty(exact_records) ? best_feasible : exact_rational(only(exact_burdens))
    benchmark_class = isempty(exact_records) ?
        "best exactly feasible returned candidate; global optimality not established" :
        "exact finite enumeration or requirement-mask dynamic programming"
    for record in records
        if record["candidate_returned"] === true && record["selection"]["exact_feasible"] === true
            burden = exact_rational(record["selection"]["exact_burden"])
            record["benchmark_burden"] = _exact_text(benchmark_burden)
            record["absolute_burden_gap"] = _exact_text(burden - benchmark_burden)
            record["relative_burden_gap"] = iszero(benchmark_burden) ? Dict("available" => false) :
                _exact_text((burden - benchmark_burden) / benchmark_burden)
        else
            record["benchmark_burden"] = Dict("available" => false)
            record["absolute_burden_gap"] = Dict("available" => false)
            record["relative_burden_gap"] = Dict("available" => false)
        end
    end
    payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-instance-result-v1",
        "experiment_id" => "financial-strategy-library-panel-v1",
        "origin_id" => String(origin_id),
        "library_id" => String(library_id),
        "schedule_id" => String(schedule_id),
        "instance_sha256" => journal_compression_instance_sha256(instance),
        "terminal" => true,
        "algorithm_terminal_row_count" => length(records),
        "registered_algorithm_ids" => collect(ALGORITHM_IDS),
        "benchmark_evidence_class" => benchmark_class,
        "benchmark_burden" => _exact_text(benchmark_burden),
        "global_optimum_exactly_verified" => !isempty(exact_records),
        "structure" => _structure(instance, preprocessing),
        "algorithms" => records,
        "postdecision_opened" => false,
        "licensed_rows_included" => false,
    )
    audit = audit_instance_result(instance, payload)
    audit["passed"] === true || error("in-memory algorithm result audit failed")
    return payload, logs
end

function audit_instance_result(instance, payload)
    errors = String[]
    payload["schema_version"] == "financial-strategy-library-panel-instance-result-v1" ||
        push!(errors, "unexpected result schema")
    payload["instance_sha256"] == journal_compression_instance_sha256(instance) ||
        push!(errors, "instance hash mismatch")
    algorithms = payload["algorithms"]
    ids = String[record["algorithm_id"] for record in algorithms]
    ids == collect(ALGORITHM_IDS) || push!(errors, "registered algorithm row order or coverage mismatch")
    for record in algorithms
        record["terminal"] === true || push!(errors, "nonterminal algorithm row")
        record["solver_status_used_as_exact_proof"] === false ||
            push!(errors, "solver status is treated as exact proof")
        record["candidate_returned"] === true || continue
        selection = record["selection"]
        indices = Int.(selection["selected_strategy_indices"])
        length(indices) == length(unique(indices)) || begin
            push!(errors, "duplicate selection index")
            continue
        end
        all(index -> index in eachindex(instance.strategy_ids), indices) || begin
            push!(errors, "selection index outside instance")
            continue
        end
        selected = falses(length(instance.strategy_ids))
        selected[indices] .= true
        recorded_ids = String.(selection["selected_strategy_ids"])
        expected_ids = [string(instance.strategy_ids[index].id) for index in indices]
        recorded_ids == expected_ids || push!(errors, "selected identifiers mismatch")
        check = check_journal_compression_solution(instance, selected)
        check.exact_feasible == selection["exact_feasible"] || push!(errors, "feasibility mismatch")
        _exact_text(check.exact_burden) == selection["exact_burden"] || push!(errors, "burden mismatch")
        check.frontier_preserved == selection["exact_frontier_preservation"] ||
            push!(errors, "frontier certificate mismatch")
        check.closure_preserved == selection["exact_closure_preservation"] ||
            push!(errors, "closure certificate mismatch")
        check.mandatory_retained == selection["exact_mandatory_retention"] ||
            push!(errors, "mandatory certificate mismatch")
    end
    return Dict{String,Any}(
        "passed" => isempty(errors),
        "errors" => errors,
        "checked_algorithm_rows" => length(algorithms),
        "licensed_rows_included" => false,
        "solver_status_used_as_exact_proof" => false,
    )
end

function registered_job_keys()
    return [
        (origin.origin_id, library.library_id, schedule_id) for
        origin in origin_rows(), library in library_rows(), schedule_id in SCHEDULE_IDS
    ]
end


function build_synthetic_smoke_instances(count::Integer = 8)
    count > 0 || throw(ArgumentError("smoke-instance count must be positive"))
    result = NamedTuple[]
    for index in 1:Int(count)
        provenance = JournalCompressionProvenance(
            :financial,
            "synthetic-smoke-$index",
            "public synthetic execution smoke; not financial evidence";
            attributes = [
                "licensed_rows_included" => "false",
                "phase" => "smoke",
            ],
            redistributable = true,
        )
        instance = journal_compression_instance_from_components(
            ["inactive", "s_a", "s_b", "s_c", "s_bundle"],
            [true, false, false, false, false],
            [0, 2 + index, 3 + index, 4 + index, 5 + index],
            ["financial_state:1", "financial_state:2"],
            [
                0 0;
                2 0;
                0 2;
                2 2;
                2 2
            ],
            [
                String[],
                ["m1"],
                ["m2"],
                ["m3"],
                ["m1", "m2", "m3"],
            ];
            tie_handling = JournalTieHandling(
                :declared_representative;
                declaration = "synthetic smoke returns one stable representative",
                stable_selector = "canonical strategy identifier",
            ),
            provenance,
        )
        push!(result, (
            origin_id = "SMOKE-O$(lpad(index, 2, '0'))",
            library_id = "full_factorial_catalog",
            schedule_id = "validation_work_units",
            instance,
        ))
    end
    return result
end


function _strategy_from_id(identifier::AbstractString)
    parts = split(identifier, '|')
    length(parts) == 9 || error("financial panel strategy identifier is malformed")
    origin_id, _, permno, signal, filter, horizon, sizing, exit_rule, risk = parts
    return _panel_strategy(
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


function _fixed_state_by_date(reference_rows, thresholds, end_date, amendment)
    observations = [row for row in reference_rows if row.date <= end_date]
    prices = _total_return_index(observations)
    lookback = Int(amendment["lookbacks"]["belief_sessions"])
    result = Dict{String,Int}()
    for index in eachindex(observations)
        feature = _lookback_return(prices, index, lookback)
        isfinite(feature) || continue
        result[observations[index].date] = searchsortedfirst(thresholds, feature)
    end
    return result
end


function _postdecision_profile(strategy, rows, state_by_date, origin, config, amendment)
    observations = [row for row in rows if row.date <= origin.postdecision_end]
    dates = getfield.(observations, :date)
    backtest = _backtest(strategy, observations, config, amendment)
    return _profile(
        backtest.net,
        dates,
        state_by_date,
        origin.postdecision_start,
        origin.postdecision_end,
        config,
    )
end


function evaluate_postdecision(
    instance,
    result_payload,
    origin::OriginUniverse,
    series,
    thresholds,
    config,
    amendment;
    next_origin_source_identities = nothing,
)
    result_payload["terminal"] === true ||
        error("postdecision phase requires a terminal structural record")
    audit = audit_instance_result(instance, result_payload)
    audit["passed"] === true ||
        error("postdecision phase requires a passing structural audit")
    haskey(series, origin.reference_permno) || error("postdecision reference series is absent")
    state_by_date = _fixed_state_by_date(
        series[origin.reference_permno],
        thresholds,
        origin.postdecision_end,
        amendment,
    )
    profile_by_index = Dict{Int,Vector{ExactRational}}()
    for index in eachindex(instance.strategy_ids)
        if instance.mandatory[index]
            profile_by_index[index] = fill(zero(ExactRational), 5)
            continue
        end
        strategy = _strategy_from_id(string(instance.strategy_ids[index].id))
        haskey(series, strategy.permno) || error("postdecision strategy series is absent")
        profile_by_index[index] = _float_exact.(_postdecision_profile(
            strategy,
            series[strategy.permno],
            state_by_date,
            origin,
            config,
            amendment,
        ))
    end
    source_frontier = [
        maximum(profile_by_index[index][state] for index in eachindex(instance.strategy_ids))
        for state in 1:5
    ]
    algorithm_rows = Dict{String,Any}[]
    for record in result_payload["algorithms"]
        if record["candidate_returned"] !== true ||
           record["selection"]["exact_feasible"] !== true
            push!(algorithm_rows, Dict{String,Any}(
                "algorithm_id" => record["algorithm_id"],
                "available" => false,
                "reason" => "no exactly feasible structural endpoint",
            ))
            continue
        end
        indices = Int.(record["selection"]["selected_strategy_indices"])
        retained_frontier = [
            maximum(profile_by_index[index][state] for index in indices) for state in 1:5
        ]
        losses = source_frontier .- retained_frontier
        all(value -> value >= zero(ExactRational), losses) ||
            error("retained postdecision frontier exceeds its source")
        active_ids = [
            string(instance.strategy_ids[index].id) for index in indices if
            !instance.mandatory[index]
        ]
        identity_tokens = Set(join(split(id, '|')[3:end], '|') for id in active_ids)
        persistence = isnothing(next_origin_source_identities) ? nothing :
            BigInt(length(intersect(identity_tokens, next_origin_source_identities))) //
            BigInt(max(length(identity_tokens), 1))
        push!(algorithm_rows, Dict{String,Any}(
            "algorithm_id" => record["algorithm_id"],
            "available" => true,
            "belief_losses" => _exact_text.(losses),
            "mean_belief_loss" => _exact_text(sum(losses) / 5),
            "no_loss_share" => _exact_text(BigInt(count(iszero, losses)) // BigInt(5)),
            "identity_persistence_to_next_origin" => isnothing(persistence) ?
                Dict("available" => false) : _exact_text(persistence),
        ))
    end
    source_permnos = Set(
        _strategy_from_id(string(instance.strategy_ids[index].id)).permno for
        index in eachindex(instance.strategy_ids) if !instance.mandatory[index]
    )
    delisted_count = count(source_permnos) do permno
        any(
            row -> origin.postdecision_start <= row.date <= origin.postdecision_end &&
                   !(row.delisting_flag in ("", "N")),
            series[permno],
        )
    end
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-postdecision-v1",
        "origin_id" => origin.origin_id,
        "library_id" => result_payload["library_id"],
        "schedule_id" => result_payload["schedule_id"],
        "structural_instance_sha256" => result_payload["instance_sha256"],
        "structural_result_terminal_and_audited_before_open" => true,
        "postdecision_window_start" => origin.postdecision_start,
        "postdecision_window_end" => origin.postdecision_end,
        "source_frontier" => _exact_text.(source_frontier),
        "source_security_count_with_delisting_flag" => delisted_count,
        "algorithms" => algorithm_rows,
        "licensed_rows_included" => false,
        "nonclaims" => ["causal", "forecasting", "alpha", "deployable performance"],
    )
end


end
