module PrepareFinancialTerminalAuditData

using SHA: sha256
using TOML

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_terminal_audit.toml",
)
const PROVENANCE_SCHEMA = "financial-illustration-provenance-v1"
const LICENSED_SOURCE_ROOT_ENV = "ALGOLIB_CRSP_ROOT"
const LICENSED_INPUT_MESSAGE =
    "Licensed CRSP/WRDS inputs are not distributed with this repository. See DATA_ACCESS.md."

function _require(condition::Bool, message::AbstractString)
    condition || error(message)
    return true
end

_repo_path(path::AbstractString) = isabspath(path) ? normpath(path) : normpath(joinpath(REPOSITORY_ROOT, path))

function _require_licensed_source(source::AbstractDict)
    configured_root = String(source["repository_root"])
    source_root = _repo_path(get(ENV, LICENSED_SOURCE_ROOT_ENV, configured_root))
    relative_paths = vcat(
        [String(source["security_history"])],
        String.(source["daily_files"]),
    )
    if !isdir(source_root)
        error(
            string(
                LICENSED_INPUT_MESSAGE,
                "\nSet ",
                LICENSED_SOURCE_ROOT_ENV,
                " to an independently licensed source root or use the configured relative layout.",
            ),
        )
    end
    missing_paths = filter(path -> !isfile(joinpath(source_root, path)), relative_paths)
    if !isempty(missing_paths)
        error(
            string(
                LICENSED_INPUT_MESSAGE,
                "\nMissing required paths beneath the licensed source root:\n  ",
                join(missing_paths, "\n  "),
            ),
        )
    end
    security_history = joinpath(source_root, first(relative_paths))
    daily_paths = [joinpath(source_root, path) for path in relative_paths[2:end]]
    source_paths = vcat([security_history], daily_paths)
    return (; source_root, security_history, daily_paths, source_paths)
end

function _stream_sha256(path::AbstractString)
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

function _column_positions(header::Vector{String}, required::Vector{String})
    positions = Dict{String,Int}()
    for column in required
        position = findfirst(==(column), header)
        _require(!isnothing(position), "source is missing required column: $column")
        positions[column] = position
    end
    return positions
end

function _validate_security_history(
    path::AbstractString,
    permnos::Dict{String,Int},
    ticker_aliases::Dict{String,Vector{String}},
    start_date::String,
    end_date::String,
)
    lines = eachline(path)
    header = _split_csv(first(lines))
    positions = _column_positions(
        header,
        ["permno", "secinfostartdt", "secinfoenddt", "ticker", "securitytype", "securitysubtype"],
    )
    start_valid = Dict(ticker => false for ticker in keys(permnos))
    end_valid = Dict(ticker => false for ticker in keys(permnos))
    target_by_identifier = Dict{Tuple{Int,String},String}()
    for (ticker, permno) in permnos
        for alias in get(ticker_aliases, ticker, [ticker])
            target_by_identifier[(permno, alias)] = ticker
        end
    end
    for line in lines
        fields = _split_csv(line)
        length(fields) == length(header) || error("security-history CSV width mismatch")
        parsed_permno = tryparse(Int, fields[positions["permno"]])
        isnothing(parsed_permno) && continue
        source_ticker = fields[positions["ticker"]]
        ticker = get(target_by_identifier, (parsed_permno, source_ticker), "")
        isempty(ticker) && continue
        _require(fields[positions["securitytype"]] == "FUND", "$ticker is not classified as FUND")
        _require(fields[positions["securitysubtype"]] == "ETF", "$ticker is not classified as ETF")
        interval_start = fields[positions["secinfostartdt"]]
        interval_end = fields[positions["secinfoenddt"]]
        interval_start <= start_date <= interval_end && (start_valid[ticker] = true)
        interval_start <= end_date <= interval_end && (end_valid[ticker] = true)
    end
    for ticker in sort!(collect(keys(permnos)))
        _require(start_valid[ticker], "$ticker/PERMNO is not date-valid at extraction start")
        _require(end_valid[ticker], "$ticker/PERMNO is not date-valid at extraction end")
    end
    return true
end

function _parse_required_float(value::AbstractString, label::AbstractString; positive::Bool = false)
    parsed = tryparse(Float64, strip(value))
    _require(!isnothing(parsed) && isfinite(parsed), "$label is missing or nonnumeric")
    positive && _require(parsed > 0, "$label must be positive")
    return parsed
end

function _extract_daily_file!(
    observations::Dict{String,Vector{NamedTuple}},
    path::AbstractString,
    ticker_by_permno::Dict{Int,String},
    start_date::String,
    end_date::String,
)
    command = `gzip -cd -- $path`
    open(command, "r") do io
        header = _split_csv(readline(io))
        positions = _column_positions(
            header,
            ["permno", "dlycaldt", "dlyret", "dlyclose", "dlyprc", "dlyvol", "dlydelflg", "dlyretmissflg"],
        )
        for line in eachline(io)
            fields = _split_csv(line)
            length(fields) == length(header) || error("daily-security CSV width mismatch in $path")
            permno = tryparse(Int, fields[positions["permno"]])
            isnothing(permno) && continue
            ticker = get(ticker_by_permno, permno, "")
            isempty(ticker) && continue
            date = fields[positions["dlycaldt"]]
            start_date <= date <= end_date || continue
            total_return = _parse_required_float(fields[positions["dlyret"]], "$ticker $date dlyret")
            _require(total_return > -1, "$ticker $date dlyret is not compoundable")
            parsed_close = tryparse(Float64, strip(fields[positions["dlyclose"]]))
            price_fallback = isnothing(parsed_close) || !isfinite(parsed_close) || parsed_close <= 0
            close = if price_fallback
                abs(_parse_required_float(fields[positions["dlyprc"]], "$ticker $date dlyprc"))
            else
                parsed_close
            end
            _require(close > 0, "$ticker $date close/price fallback must be positive")
            volume = _parse_required_float(fields[positions["dlyvol"]], "$ticker $date dlyvol")
            _require(volume >= 0, "$ticker $date volume is negative")
            delisting_flag = fields[positions["dlydelflg"]]
            return_missing_flag = fields[positions["dlyretmissflg"]]
            push!(observations[ticker], (; date, total_return, close, volume, delisting_flag, return_missing_flag, price_fallback))
        end
    end
    return observations
end

function _prepare_rows(observations::Dict{String,Vector{NamedTuple}}, tickers::Vector{String})
    rows = NamedTuple[]
    audit_rows = NamedTuple[]
    for ticker in tickers
        ticker_rows = sort!(observations[ticker]; by = row -> row.date)
        _require(!isempty(ticker_rows), "no observations were extracted for $ticker")
        dates = getfield.(ticker_rows, :date)
        _require(length(unique(dates)) == length(dates), "duplicate dates were extracted for $ticker")
        total_return_index = 100.0
        delisting_rows = 0
        nonblank_missing_flags = 0
        price_fallback_rows = 0
        for (index, row) in enumerate(ticker_rows)
            index > 1 && (total_return_index *= 1 + row.total_return)
            isfinite(total_return_index) && total_return_index > 0 || error("invalid compounded return index for $ticker $(row.date)")
            row.delisting_flag != "N" && (delisting_rows += 1)
            !(row.return_missing_flag in ("", "NA")) && (nonblank_missing_flags += 1)
            row.price_fallback && (price_fallback_rows += 1)
            push!(rows, (
                date = row.date,
                ticker,
                total_return_index,
                close = row.close,
                volume = row.volume,
            ))
        end
        push!(audit_rows, (
            ticker,
            permno = 0,
            first_date = first(dates),
            last_date = last(dates),
            observations = length(ticker_rows),
            duplicate_dates = 0,
            missing_required_values = 0,
            delisting_flag_rows = delisting_rows,
            nonblank_return_missing_flag_rows = nonblank_missing_flags,
            dlyprc_fallback_rows = price_fallback_rows,
        ))
    end
    sort!(rows; by = row -> (row.date, row.ticker))
    return rows, audit_rows
end

function _csv_escape(value)
    text = string(value)
    return occursin(r"[\",\n\r]", text) ? "\"$(replace(text, "\"" => "\"\""))\"" : text
end

function _write_csv(path::AbstractString, columns, rows)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, join(columns, ","))
        for row in rows
            println(io, join((_csv_escape(getproperty(row, Symbol(column))) for column in columns), ","))
        end
    end
    return path
end

function _write_provenance(
    path::AbstractString,
    data_path::AbstractString,
    source_root::AbstractString,
    source_paths::Vector{String},
    source_hashes::Vector{String},
    config::AbstractDict,
    rows,
    orats_inventory_revalidated::Bool,
)
    source = config["source"]
    tickers = String.(config["universe"]["tickers"])
    provenance = Dict{String,Any}(
        "schema_version" => PROVENANCE_SCHEMA,
        "provider" => source["provider"],
        "dataset_name" => source["dataset_name"],
        "source_url_or_delivery_id" => "local sibling repository $(source["repository_commit"])",
        "license_name" => "CRSP/WRDS institutional license; raw redistribution prohibited",
        "license_url_or_text_reference" => source["license_reference"],
        "license_allows_research_use" => true,
        "raw_data_redistribution_permitted" => false,
        "aggregate_outputs_publishable" => source["aggregate_outputs_publishable"],
        "derived_output_publication_status" => source["derived_output_publication_status"],
        "reviewer_replication_access" => source["reviewer_replication_access"],
        "retrieved_at_utc" => "2026-04-30T23:53:32Z",
        "retrieval_timestamp_basis" => "latest local source-file modification time; original WRDS query timestamp unavailable",
        "file_sha256" => _stream_sha256(data_path),
        "exchange_timezone" => config["data"]["exchange_timezone"],
        "date_field_semantics" => "CRSP dlycaldt trading date; dlyclose is the exchange-session close",
        "field_availability" => "Signals use fields through close t; configured execution begins no earlier than close t+1 and first earns t+1-to-t+2 return",
        "total_return_construction" => "Per-PERMNO index compounded from CRSP dlyret; dlyret includes ordinary distributions according to the source schema",
        "corporate_action_revision_policy" => "Fixed CRSP snapshot; historical corrections and corporate-action revisions after the original trading date are possible",
        "universe_selection_notes" => "Fixed $(length(tickers))-ETF universe chosen before CRSP return extraction from the audited ORATS-covered set plus declared CRSP addition(s)",
        "survivorship_notes" => "All declared funds survive through the locked period; this ex-post fixed universe is not survivorship-free",
        "known_missingness" => "Required returns and volumes are fail-closed; EMB 2008-02-20 uses absolute dlyprc for the missing/nonpositive dlyclose audit field; analysis intersects complete dates and reports exclusions",
        "stale_price_and_correction_policy" => "No interpolation or forward fill; current-snapshot corrections are not separately timestamped",
        "point_in_time_attested" => false,
        "point_in_time_status" => "point_in_time_conscious_but_not_certified_current_snapshot",
        "attested_by" => "automated audit of supplied local files and sibling-repository source records",
        "attested_at_utc" => "2026-07-20T00:00:00Z",
        "source_repository_root" => relpath(source_root, REPOSITORY_ROOT),
        "source_repository_commit" => source["repository_commit"],
        "source_files" => [
            Dict(
                "path" => relpath(source_path, source_root),
                "sha256" => source_hash,
                "bytes" => filesize(source_path),
            ) for (source_path, source_hash) in zip(source_paths, source_hashes)
        ],
        "tickers" => tickers,
        "orats_covered_tickers" => String.(config["universe"]["orats_covered_tickers"]),
        "crsp_only_additions" => String.(config["universe"]["crsp_only_additions"]),
        "excluded_orats_tickers" => String.(config["universe"]["excluded_orats_tickers"]),
        "orats_exclusion_reason" => config["universe"]["exclusion_reason"],
        "orats_inventory_revalidated" => orats_inventory_revalidated,
        "orats_inventory_required_for_replication" => source["orats_inventory_required"],
        "extracted_rows" => length(rows),
        "extract_start" => source["extract_start"],
        "extract_end" => source["extract_end"],
    )
    open(path, "w") do io
        TOML.print(io, provenance; sorted = true)
    end
    return provenance
end

function prepare(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    source = config["source"]
    licensed_source = _require_licensed_source(source)
    source_root = licensed_source.source_root
    orats_inventory_root = normpath(joinpath(source_root, source["orats_inventory_root"]))
    orats_inventory_revalidated = isdir(orats_inventory_root)
    if orats_inventory_revalidated
        for ticker in String.(config["universe"]["orats_covered_tickers"])
            _require(isdir(joinpath(orats_inventory_root, ticker)), "declared ORATS-covered ETF is absent: $ticker")
        end
        for ticker in String.(config["universe"]["excluded_orats_tickers"])
            _require(isdir(joinpath(orats_inventory_root, ticker)), "declared ORATS exclusion is absent: $ticker")
        end
    else
        _require(
            source["orats_inventory_required"] === false,
            "ORATS inventory root is absent: $orats_inventory_root",
        )
        println("ORATS inventory is absent; using the frozen ticker/PERMNO universe without re-auditing its origin")
    end
    for ticker in String.(config["universe"]["excluded_orats_tickers"])
        _require(!(ticker in config["universe"]["tickers"]), "excluded ORATS ticker remains in the universe: $ticker")
    end
    security_history = licensed_source.security_history
    daily_paths = licensed_source.daily_paths
    source_paths = licensed_source.source_paths

    tickers = String.(config["universe"]["tickers"])
    permnos = Dict(ticker => Int(source["permno"][ticker]) for ticker in tickers)
    ticker_aliases = Dict(
        ticker => haskey(source["ticker_aliases"], ticker) ?
                  String.(source["ticker_aliases"][ticker]) : [ticker] for ticker in tickers
    )
    _require(length(unique(values(permnos))) == length(permnos), "configured PERMNOs are not unique")
    _validate_security_history(
        security_history,
        permnos,
        ticker_aliases,
        source["extract_start"],
        source["extract_end"],
    )

    observations = Dict{String,Vector{NamedTuple}}(ticker => NamedTuple[] for ticker in tickers)
    ticker_by_permno = Dict(permno => ticker for (ticker, permno) in permnos)
    for path in daily_paths
        println("extracting restricted source: $(basename(path))")
        _extract_daily_file!(observations, path, ticker_by_permno, source["extract_start"], source["extract_end"])
    end
    rows, audit_rows = _prepare_rows(observations, tickers)
    audit_rows = [merge(row, (permno = permnos[row.ticker],)) for row in audit_rows]

    data_path = _repo_path(config["data"]["path"])
    provenance_path = _repo_path(config["data"]["provenance_path"])
    audit_path = joinpath(dirname(data_path), "source_extract_audit.csv")
    _write_csv(data_path, ("date", "ticker", "total_return_index", "close", "volume"), rows)
    _write_csv(
        audit_path,
        (
            "ticker",
            "permno",
            "first_date",
            "last_date",
            "observations",
            "duplicate_dates",
            "missing_required_values",
            "delisting_flag_rows",
            "nonblank_return_missing_flag_rows",
            "dlyprc_fallback_rows",
        ),
        audit_rows,
    )

    println("hashing restricted source files for provenance")
    source_hashes = [_stream_sha256(path) for path in source_paths]
    provenance = _write_provenance(
        provenance_path,
        data_path,
        source_root,
        source_paths,
        source_hashes,
        config,
        rows,
        orats_inventory_revalidated,
    )
    println("wrote local nonredistributable extract: $data_path")
    println("rows=$(length(rows)); data_sha256=$(provenance["file_sha256"])")
    println("derived-output publication status=$(provenance["derived_output_publication_status"])")
    return (; data_path, provenance_path, audit_path, rows = length(rows))
end

function main(args = ARGS)
    positional = [argument for argument in args if !startswith(argument, "--")]
    config_path = isempty(positional) ? DEFAULT_CONFIG : only(positional)
    return prepare(config_path)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    PrepareFinancialTerminalAuditData.main()
end
