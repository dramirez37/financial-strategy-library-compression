module AuditFinancialAnnualUniverse

using SHA: sha256
using TOML

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_annual_universe_audit.toml",
)
const CONFIG_SCHEMA = "financial-universe-audit-v2"
const SELECTION_SCHEMA = "financial-universe-selection-v2"
const LICENSED_SOURCE_ROOT_ENV = "ALGOLIB_CRSP_ROOT"
const LICENSED_INPUT_MESSAGE =
    "Licensed CRSP/WRDS inputs are not distributed with this repository. See DATA_ACCESS.md."

_require(condition::Bool, message::AbstractString) = condition ? true : error(message)
_repo_path(path::AbstractString) = isabspath(path) ? normpath(path) : normpath(joinpath(REPOSITORY_ROOT, path))

function _sha256_file(path::AbstractString)
    open(path, "r") do io
        return bytes2hex(sha256(io))
    end
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
            _require(position(buffer) == 0, "quote begins inside an unquoted CSV field")
            quoted = true
        elseif character == ','
            push!(fields, String(take!(buffer)))
        else
            write(buffer, character)
        end
        index = nextind(line, index)
    end
    _require(!quoted, "unterminated quoted CSV field")
    push!(fields, String(take!(buffer)))
    return fields
end

function _positions(header::Vector{String}, required)
    result = Dict{String,Int}()
    for column in required
        index = findfirst(==(column), header)
        _require(!isnothing(index), "source is missing required column: $column")
        result[column] = index
    end
    return result
end

function _endpoint_etfs(path::AbstractString, config::AbstractDict)
    window = config["window"]
    eligibility = config["eligibility"]
    start_date = String(window["classification_start"])
    end_date = String(window["analysis_end"])
    lines = eachline(path)
    header = _split_csv(first(lines))
    positions = _positions(
        header,
        (
            "permno",
            "secinfostartdt",
            "secinfoenddt",
            "ticker",
            "securitynm",
            "securitytype",
            "securitysubtype",
            "securityactiveflg",
        ),
    )
    start_rows = Dict{Int,NamedTuple}()
    end_rows = Dict{Int,NamedTuple}()
    for line in lines
        fields = _split_csv(line)
        length(fields) == length(header) || error("security-history CSV width mismatch")
        fields[positions["securitytype"]] == eligibility["security_type"] || continue
        fields[positions["securitysubtype"]] == eligibility["security_subtype"] || continue
        permno = tryparse(Int, fields[positions["permno"]])
        isnothing(permno) && continue
        row = (
            ticker = fields[positions["ticker"]],
            security_name = fields[positions["securitynm"]],
            active = fields[positions["securityactiveflg"]],
        )
        interval_start = fields[positions["secinfostartdt"]]
        interval_end = fields[positions["secinfoenddt"]]
        interval_start <= start_date <= interval_end && (start_rows[permno] = row)
        interval_start <= end_date <= interval_end && (end_rows[permno] = row)
    end
    return start_rows, end_rows
end

function _parse_number(value::AbstractString)
    parsed = tryparse(Float64, strip(value))
    return isnothing(parsed) || !isfinite(parsed) ? nothing : parsed
end

function _scan_liquidity!(stats, path::AbstractString, config::AbstractDict)
    window = config["window"]
    start_date = String(window["classification_start"])
    end_date = String(window["analysis_end"])
    liquidity_start = String(window["liquidity_start"])
    liquidity_end = String(window["liquidity_end"])
    target_permnos = Set(keys(stats))
    open(`gzip -cd -- $path`, "r") do io
        header = _split_csv(readline(io))
        positions = _positions(
            header,
            ("permno", "dlycaldt", "dlyclose", "dlyprc", "dlyvol", "dlydelflg"),
        )
        for line in eachline(io)
            fields = _split_csv(line)
            length(fields) == length(header) || error("daily-security CSV width mismatch in $path")
            permno = tryparse(Int, fields[positions["permno"]])
            isnothing(permno) && continue
            permno in target_permnos || continue
            date = fields[positions["dlycaldt"]]
            start_date <= date <= end_date || continue
            entry = stats[permno]
            entry.full_observations += 1
            fields[positions["dlydelflg"]] != "N" && (entry.delisting_rows += 1)
            liquidity_start <= date <= liquidity_end || continue
            entry.liquidity_observations += 1
            close = _parse_number(fields[positions["dlyclose"]])
            if isnothing(close) || close <= 0
                close = _parse_number(fields[positions["dlyprc"]])
                !isnothing(close) && (close = abs(close))
            end
            volume = _parse_number(fields[positions["dlyvol"]])
            if isnothing(close) || close <= 0 || isnothing(volume) || volume < 0
                entry.invalid_liquidity_rows += 1
            else
                push!(entry.closes, close)
                push!(entry.dollar_volumes, close * volume)
            end
        end
    end
    return stats
end

function _median(values::Vector{Float64})
    isempty(values) && return NaN
    ordered = sort(values)
    middle = length(ordered) ÷ 2
    return isodd(length(ordered)) ? ordered[middle + 1] : (ordered[middle] + ordered[middle + 1]) / 2
end

function _csv_escape(value)
    text = value isa Bool ? (value ? "true" : "false") : string(value)
    return occursin(r"[\",\n\r]", text) ? "\"$(replace(text, "\"" => "\"\""))\"" : text
end

function _write_csv(path::AbstractString, rows)
    columns = keys(first(rows))
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, join(string.(columns), ","))
        for row in rows
            println(io, join((_csv_escape(getproperty(row, column)) for column in columns), ","))
        end
    end
    return path
end

function audit(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    _require(config["schema_version"] == CONFIG_SCHEMA, "unsupported universe-audit schema")
    source_root = _repo_path(
        get(ENV, LICENSED_SOURCE_ROOT_ENV, String(config["source"]["repository_root"])),
    )
    security_history = joinpath(source_root, config["source"]["security_history"])
    daily_files = [joinpath(source_root, path) for path in String.(config["source"]["daily_files"])]
    source_paths = vcat([security_history], daily_files)
    missing_paths = filter(path -> !isfile(path), source_paths)
    if !isempty(missing_paths)
        relative_missing_paths = [relpath(path, source_root) for path in missing_paths]
        error(
            string(
                LICENSED_INPUT_MESSAGE,
                "\nSet ",
                LICENSED_SOURCE_ROOT_ENV,
                " to an independently licensed source root.",
                "\nMissing required paths beneath the licensed source root:\n  ",
                join(relative_missing_paths, "\n  "),
            ),
        )
    end

    start_rows, end_rows = _endpoint_etfs(security_history, config)
    endpoint_permnos = sort!(collect(intersect(keys(start_rows), keys(end_rows))))
    stats = Dict(
        permno => MutableAuditStats(Float64[], Float64[], 0, 0, 0, 0) for
        permno in endpoint_permnos
    )
    for path in daily_files
        println("auditing price/volume only: $(basename(path))")
        _scan_liquidity!(stats, path, config)
    end

    eligibility = config["eligibility"]
    aliases = Dict(String(key) => String(value) for (key, value) in eligibility["allowed_ticker_change"])
    keywords = uppercase.(String.(eligibility["exclude_name_keywords"]))
    preliminary = NamedTuple[]
    for permno in endpoint_permnos
        start_row = start_rows[permno]
        end_row = end_rows[permno]
        entry = stats[permno]
        canonical_ticker = end_row.ticker
        allowed_change = start_row.ticker == end_row.ticker || get(aliases, start_row.ticker, "") == end_row.ticker
        active_endpoints = start_row.active == "Y" && end_row.active == "Y"
        name_text = uppercase("$(start_row.security_name) $(end_row.security_name)")
        matched_keyword = something(findfirst(keyword -> occursin(keyword, name_text), keywords), 0)
        excluded_keyword = matched_keyword == 0 ? "" : keywords[matched_keyword]
        median_close = _median(entry.closes)
        median_dollar_volume = _median(entry.dollar_volumes)
        reasons = String[]
        !allowed_change && push!(reasons, "unapproved_ticker_change")
        eligibility["require_active_at_both_endpoints"] && !active_endpoints && push!(reasons, "inactive_endpoint")
        entry.liquidity_observations < eligibility["minimum_liquidity_observations"] && push!(reasons, "insufficient_liquidity_history")
        entry.full_observations < eligibility["minimum_full_window_observations"] && push!(reasons, "insufficient_full_history")
        entry.invalid_liquidity_rows > 0 && push!(reasons, "invalid_price_or_volume")
        entry.delisting_rows > 0 && push!(reasons, "delisting_flag")
        (!isfinite(median_close) || median_close < eligibility["minimum_median_close"]) && push!(reasons, "price_floor")
        (!isfinite(median_dollar_volume) || median_dollar_volume < eligibility["minimum_median_dollar_volume"]) && push!(reasons, "dollar_volume_floor")
        !isempty(excluded_keyword) && push!(reasons, "complex_product_keyword:$excluded_keyword")
        push!(preliminary, (
            permno,
            start_ticker = start_row.ticker,
            end_ticker = end_row.ticker,
            canonical_ticker,
            start_security_name = start_row.security_name,
            end_security_name = end_row.security_name,
            full_observations = entry.full_observations,
            liquidity_observations = entry.liquidity_observations,
            invalid_liquidity_rows = entry.invalid_liquidity_rows,
            delisting_rows = entry.delisting_rows,
            median_close,
            median_dollar_volume,
            endpoint_eligible = isempty(reasons),
            exclusion_reason = isempty(reasons) ? "" : join(reasons, ";"),
        ))
    end
    eligible = sort!([row for row in preliminary if row.endpoint_eligible]; by = row -> (-row.median_dollar_volume, row.permno))
    maximum_selected = Int(eligibility["maximum_selected"])
    selected_permnos = Set(row.permno for row in first(eligible, min(maximum_selected, length(eligible))))
    ranks = Dict(row.permno => rank for (rank, row) in enumerate(eligible))
    rows = [merge(row, (
        liquidity_rank = get(ranks, row.permno, 0),
        selected = row.permno in selected_permnos,
        decision = row.permno in selected_permnos ? "include" : row.endpoint_eligible ? "exclude_below_top_n" : "exclude_ineligible",
    )) for row in preliminary]
    sort!(rows; by = row -> (row.selected ? 0 : 1, row.liquidity_rank == 0 ? typemax(Int) : row.liquidity_rank, row.permno))
    selected = [row for row in rows if row.selected]
    _require(length(selected) == maximum_selected, "fewer eligible ETFs than the configured maximum")
    reference = String(eligibility["required_reference_ticker"])
    _require(any(row -> row.canonical_ticker == reference, selected), "required reference ETF is not selected")
    _require(length(unique(getfield.(selected, :canonical_ticker))) == length(selected), "selected canonical tickers are not unique")

    audit_path = _repo_path(config["outputs"]["audit_csv"])
    selection_path = _repo_path(config["outputs"]["selection_toml"])
    _write_csv(audit_path, rows)
    selection = Dict{String,Any}(
        "schema_version" => SELECTION_SCHEMA,
        "audit_id" => config["audit_id"],
        "protocol_date" => config["protocol_date"],
        "source_repository_commit" => config["source_repository_commit"],
        "source_security_history_sha256" => _sha256_file(security_history),
        "audit_config_sha256" => _sha256_file(config_path),
        "outcome_fields_read" => false,
        "selection_basis" => "endpoint FUND/ETF identity, development-period price/volume eligibility, and predeclared name exclusions; dlyret was not parsed",
        "eligible_count" => length(eligible),
        "selected_count" => length(selected),
        "selected" => [Dict(
            "ticker" => row.canonical_ticker,
            "permno" => row.permno,
            "start_ticker" => row.start_ticker,
            "end_ticker" => row.end_ticker,
            "liquidity_rank" => row.liquidity_rank,
        ) for row in selected],
    )
    mkpath(dirname(selection_path))
    open(selection_path, "w") do io
        TOML.print(io, selection; sorted = true)
    end
    println("endpoint_etfs=$(length(endpoint_permnos)); eligible=$(length(eligible)); selected=$(length(selected))")
    println("wrote $audit_path")
    println("wrote $selection_path")
    return (; rows, selected, audit_path, selection_path)
end

mutable struct MutableAuditStats
    closes::Vector{Float64}
    dollar_volumes::Vector{Float64}
    full_observations::Int
    liquidity_observations::Int
    invalid_liquidity_rows::Int
    delisting_rows::Int
end

function main(args = ARGS)
    positional = [argument for argument in args if !startswith(argument, "--")]
    config_path = isempty(positional) ? DEFAULT_CONFIG : only(positional)
    return audit(config_path)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    AuditFinancialAnnualUniverse.main()
end
