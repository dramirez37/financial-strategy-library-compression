module PrepareFinancialAnnualWalkforwardAuditData

using SHA: sha256
using TOML

include(joinpath(@__DIR__, "prepare_financial_terminal_audit_data.jl"))
include(joinpath(@__DIR__, "freeze_financial_annual_walkforward_audit.jl"))
const TerminalPreparation = PrepareFinancialTerminalAuditData
const DesignLock = FreezeFinancialAnnualWalkforwardAudit

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_annual_walkforward_audit.toml",
)
const CONFIG_SCHEMA = "financial-illustration-v2"
const SELECTION_SCHEMA = "financial-universe-selection-v2"
const PROVENANCE_SCHEMA = "financial-illustration-provenance-v2"

_require(condition::Bool, message::AbstractString) = condition ? true : error(message)
_repo_path(path::AbstractString) = isabspath(path) ? normpath(path) : normpath(joinpath(REPOSITORY_ROOT, path))

function _sha256_file(path::AbstractString)
    open(path, "r") do io
        return bytes2hex(sha256(io))
    end
end

function _load_selection(config::AbstractDict)
    path = _repo_path(config["universe"]["selection_manifest"])
    _require(isfile(path), "universe selection manifest is absent: $path")
    _require(_sha256_file(path) == config["universe"]["selection_manifest_sha256"], "universe selection manifest hash differs from the protocol")
    selection = TOML.parsefile(path)
    _require(selection["schema_version"] == SELECTION_SCHEMA, "unsupported universe selection schema")
    _require(selection["outcome_fields_read"] === false, "universe selection was not outcome blind")
    rows = selection["selected"]
    _require(length(rows) == config["universe"]["expected_count"], "selected universe count differs from the protocol")
    tickers = String[row["ticker"] for row in rows]
    permnos = Dict(String(row["ticker"]) => Int(row["permno"]) for row in rows)
    aliases = Dict(
        String(row["ticker"]) => unique(String[row["start_ticker"], row["end_ticker"]]) for
        row in rows
    )
    _require(length(unique(tickers)) == length(tickers), "selected tickers are not unique")
    _require(length(unique(values(permnos))) == length(permnos), "selected PERMNOs are not unique")
    return (; path, selection, rows, tickers, permnos, aliases)
end

function _write_provenance(
    path::AbstractString,
    data_path::AbstractString,
    source_root::AbstractString,
    source_paths::Vector{String},
    source_hashes::Vector{String},
    config::AbstractDict,
    selection,
    rows,
)
    provenance = Dict{String,Any}(
        "schema_version" => PROVENANCE_SCHEMA,
        "provider" => config["source"]["provider"],
        "dataset_name" => config["source"]["dataset_name"],
        "source_url_or_delivery_id" => "local sibling repository $(config["source"]["repository_commit"])",
        "license_name" => "CRSP/WRDS institutional license; raw redistribution prohibited",
        "license_url_or_text_reference" => config["source"]["license_reference"],
        "license_allows_research_use" => true,
        "raw_data_redistribution_permitted" => false,
        "aggregate_outputs_publishable" => config["source"]["aggregate_outputs_publishable"],
        "reviewer_replication_access" => config["source"]["reviewer_replication_access"],
        "retrieved_at_utc" => "2026-04-30T23:53:32Z",
        "retrieval_timestamp_basis" => "latest local source-file modification time; original WRDS query timestamp unavailable",
        "file_sha256" => _sha256_file(data_path),
        "exchange_timezone" => config["data"]["exchange_timezone"],
        "date_field_semantics" => "CRSP dlycaldt trading date; dlyclose is the exchange-session close",
        "field_availability" => "signals use fields through close t; the configured lag begins return exposure no earlier than t+1 to t+2",
        "total_return_construction" => "per-PERMNO total-return index compounded from CRSP dlyret",
        "corporate_action_revision_policy" => "fixed current CRSP snapshot; historical revisions are not timestamped",
        "known_missingness" => "required returns and volumes fail closed; no interpolation or forward fill",
        "point_in_time_attested" => false,
        "point_in_time_status" => "point_in_time_conscious_but_not_certified_current_snapshot",
        "survivorship_notes" => config["universe"]["survivorship_boundary"],
        "universe_selection_manifest" => relpath(selection.path, REPOSITORY_ROOT),
        "universe_selection_manifest_sha256" => config["universe"]["selection_manifest_sha256"],
        "universe_selection_outcome_fields_read" => false,
        "universe_selection_rule" => config["universe"]["selection_rule"],
        "source_repository_root" => relpath(source_root, REPOSITORY_ROOT),
        "source_repository_commit" => config["source"]["repository_commit"],
        "source_files" => [Dict(
            "path" => relpath(source_path, source_root),
            "sha256" => source_hash,
            "bytes" => filesize(source_path),
        ) for (source_path, source_hash) in zip(source_paths, source_hashes)],
        "tickers" => selection.tickers,
        "permnos" => Dict(ticker => selection.permnos[ticker] for ticker in selection.tickers),
        "extracted_rows" => length(rows),
        "extract_start" => config["source"]["extract_start"],
        "extract_end" => config["source"]["extract_end"],
    )
    mkpath(dirname(path))
    open(path, "w") do io
        TOML.print(io, provenance; sorted = true)
    end
    return provenance
end

function _write_data_audit(path::AbstractString, config, selection, audit_rows, provenance)
    mkpath(dirname(path))
    minimum_observations = minimum(row.observations for row in audit_rows)
    maximum_observations = maximum(row.observations for row in audit_rows)
    fallback_rows = sum(row.dlyprc_fallback_rows for row in audit_rows)
    delisting_rows = sum(row.delisting_flag_rows for row in audit_rows)
    missing_flag_rows = sum(row.nonblank_return_missing_flag_rows for row in audit_rows)
    open(path, "w") do io
        println(io, "# Annual Walk-Forward Financial Audit: Data Audit\n")
        println(io, "- Protocol: `$(config["experiment_id"])`")
        println(io, "- Source-repository commit: `$(config["source"]["repository_commit"])`")
        println(io, "- Universe-selection SHA-256: `$(config["universe"]["selection_manifest_sha256"])`")
        println(io, "- Outcome fields read during universe selection: **false**")
        println(io, "- Selected instruments: **$(length(selection.tickers)) ETFs**\n")
        println(io, "## Source, rights, and timestamps\n")
        println(io, "The input is the existing licensed CRSP/WRDS daily-security and date-varying security-history snapshot in the sibling repository. No download was made. Raw and row-level inputs and derivatives remain nonredistributable; the project-authored aggregate tables, figures, metadata, and reports are publishable. Reviewers rerun the scripts with their own licensed CRSP/WRDS files. `dlycaldt` is the exchange trading date, signals use information through close `t`, and the two-index lag prevents earning the contemporaneous close-to-close return. The snapshot is point-in-time-conscious but not revision-timestamped.\n")
        println(io, "## Outcome-blind universe construction\n")
        println(io, "The universe audit first found 427 PERMNOs classified `FUND`/`ETF` at both the 2008 and 2024 endpoints. It then used only identity, price, volume, and flag fields from 2009--2014: no `dlyret` value was parsed. Predeclared gates required sufficient history, a median close of at least \$5, median daily dollar volume of at least \$5 million, active endpoint records, and no delisting or invalid liquidity row. Because CRSP often reports only a trust name, the fail-closed rule excludes ProShares and Direxion trust families rather than attempting to infer leverage from missing product names. The top 100 remaining identities by development-period median dollar volume were frozen in `universe_selection.toml` before return extraction.\n")
        println(io, "## Extraction and missingness\n")
        println(io, "The restricted derivative contains $(provenance["extracted_rows"]) rows. Per-fund observation counts range from $minimum_observations to $maximum_observations. The audit found $delisting_rows delisting-flag rows, $missing_flag_rows nonblank return-missing flags, and $fallback_rows close-field fallbacks. Required returns and volumes fail closed; prices are not interpolated or forward-filled. The analysis later intersects common dates and reports any removed sessions.\n")
        println(io, "## Costs and claim boundary\n")
        println(io, "The base calculation charges $(config["backtest"]["one_way_transaction_cost_bps"]) basis points one way, with frozen $(join(config["backtest"]["cost_sensitivity_bps"], "/"))-basis-point sensitivities. These reduced-form costs omit time-varying spreads, impact, capacity, taxes, and financing. The surviving ETF universe remains subject to survivorship bias, and the 2020--2024 walk-forward audit is retrospective. The experiment tests finite-library mechanisms and does not support a market-alpha claim.")
    end
    return path
end

function prepare(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    _require(config["schema_version"] == CONFIG_SCHEMA, "unsupported annual walk-forward financial-audit config schema")
    DesignLock.verify_design_lock(config)
    selection = _load_selection(config)
    licensed_source = TerminalPreparation._require_licensed_source(config["source"])
    source_root = licensed_source.source_root
    security_history = licensed_source.security_history
    daily_paths = licensed_source.daily_paths
    source_paths = licensed_source.source_paths

    TerminalPreparation._validate_security_history(
        security_history,
        selection.permnos,
        selection.aliases,
        config["source"]["extract_start"],
        config["source"]["extract_end"],
    )
    observations = Dict{String,Vector{NamedTuple}}(ticker => NamedTuple[] for ticker in selection.tickers)
    ticker_by_permno = Dict(permno => ticker for (ticker, permno) in selection.permnos)
    for path in daily_paths
        println("extracting selected ETF returns: $(basename(path))")
        TerminalPreparation._extract_daily_file!(
            observations,
            path,
            ticker_by_permno,
            config["source"]["extract_start"],
            config["source"]["extract_end"],
        )
    end
    rows, audit_rows = TerminalPreparation._prepare_rows(observations, selection.tickers)
    audit_rows = [merge(row, (permno = selection.permnos[row.ticker],)) for row in audit_rows]

    data_path = _repo_path(config["data"]["path"])
    provenance_path = _repo_path(config["data"]["provenance_path"])
    source_audit_path = _repo_path(config["data"]["source_extract_audit_path"])
    TerminalPreparation._write_csv(data_path, ("date", "ticker", "total_return_index", "close", "volume"), rows)
    TerminalPreparation._write_csv(
        source_audit_path,
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
    source_hashes = [_sha256_file(path) for path in source_paths]
    provenance = _write_provenance(
        provenance_path,
        data_path,
        source_root,
        source_paths,
        source_hashes,
        config,
        selection,
        rows,
    )
    _write_data_audit(
        _repo_path(config["outputs"]["data_audit_md"]),
        config,
        selection,
        audit_rows,
        provenance,
    )
    println("rows=$(length(rows)); funds=$(length(selection.tickers)); data_sha256=$(provenance["file_sha256"])")
    return (; data_path, provenance_path, source_audit_path, rows = length(rows))
end

function main(args = ARGS)
    positional = [argument for argument in args if !startswith(argument, "--")]
    config_path = isempty(positional) ? DEFAULT_CONFIG : only(positional)
    return prepare(config_path)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    PrepareFinancialAnnualWalkforwardAuditData.main()
end
