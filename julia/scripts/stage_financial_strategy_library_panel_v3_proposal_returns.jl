module StageFinancialStrategyLibraryPanelV3ProposalReturns

using Parquet
using SHA: sha256
using Tables
using TOML

include(joinpath(@__DIR__, "stage_financial_strategy_library_panel_v3_predecision_returns.jl"))
const MaskedReader = StageFinancialStrategyLibraryPanelV3PredecisionReturns

export proposal_leakage_sentinel, stage_proposal_returns

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const EXECUTION_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_EXECUTION_LOCK.toml")
const PREDECISION_COMPUTATION_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PREDECISION_COMPUTATION_LOCK_002.toml")
const PREDECISION_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PREDECISION_COMPUTATION_RESULT_SEAL.toml")
const EXPECTED_PREDECISION_RESULT_SEAL_SHA256 =
    "6d879cbf17c17337d0efb502605f71f75f5f174f29d1e0a5ef9945d9ff11902d"
const PREDECISION_RESULT_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "predecision_computation",
    "PREDECISION_COMPUTATION_MANIFEST.toml",
)
const PREDECISION_STAGE_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "predecision_stage",
    "PREDECISION_STAGE_MANIFEST.toml",
)
const LOCAL_PREDECISION_STAGE_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "predecision",
    "PREDECISION_STAGE_LOCAL_MANIFEST.toml",
)
const SELECTION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "universe_census",
    "UNIVERSE_SELECTIONS.toml",
)
const ORIGIN_PATH = joinpath(EXPERIMENT_ROOT, "registry", "ORIGIN_REGISTRY.csv")
const MASTER_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2",
    "local_data",
    "master_market_panel",
)
const MASTER_MANIFEST_PATH = joinpath(MASTER_ROOT, "MASTER_MANIFEST.toml")
const LOCAL_STAGE_ROOT = joinpath(EXPERIMENT_ROOT, "local_data", "proposal")
const LOCAL_STAGE_MANIFEST_PATH = joinpath(
    LOCAL_STAGE_ROOT,
    "PROPOSAL_STAGE_LOCAL_MANIFEST.toml",
)
const PUBLIC_STAGE_ROOT = joinpath(EXPERIMENT_ROOT, "proposal_stage")
const PUBLIC_STAGE_MANIFEST_PATH = joinpath(PUBLIC_STAGE_ROOT, "PROPOSAL_STAGE_MANIFEST.toml")

struct ProposalCell
    cell_index::Int
    origin_id::String
    universe_id::String
    role::String
    universe_status::String
    gate_passed::Bool
    proposal_year::Int
    evaluation_year::Int
    decision_date::String
    selected_permnos::Set{Int}
    predecision_relative_path::String
    predecision_sha256::String
end

mutable struct SparseProposalBuffer
    permno::Vector{Int64}
    date::Vector{String}
    total_return::Vector{Union{Missing,Float64}}
    return_available::Vector{Bool}
    terminal_delisting::Vector{Bool}
    return_flag::Vector{String}
    delisting_flag::Vector{String}
end

SparseProposalBuffer() = SparseProposalBuffer(
    Int64[], String[], Union{Missing,Float64}[], Bool[], Bool[], String[], String[],
)

struct TargetRow
    row_index::Int
    permno::Int
    date::String
    cell_indices::Vector{Int}
end

struct ProposalChunk
    buffers::Vector{SparseProposalBuffer}
    reference_dates::Dict{Int,Set{String}}
    source_rows::Int
    materialized_rows::Int
    source_sha256::String
end

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

_sha256_text(value) = bytes2hex(sha256(codeunits(String(value))))

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _csv_rows(path)
    lines = filter(!isempty, strip.(readlines(path)))
    header = split(first(lines), ',')
    return [
        Dict(String(key) => String(value) for (key, value) in zip(header, split(line, ',')))
        for line in Iterators.drop(lines, 1)
    ]
end

function _write_new_or_identical(path, content)
    if isfile(path)
        read(path, String) == content || error("refusing to replace nonidentical proposal artifact")
        return path
    end
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, content)
    end
    mv(temporary, path)
    return path
end

function _install_parquet(path, table; check)
    mktempdir() do directory
        candidate = joinpath(directory, basename(path))
        Parquet.write_parquet(candidate, table)
        digest = _sha256_file(candidate)
        bytes = filesize(candidate)
        if check
            isfile(path) || error("proposal-stage parquet is absent")
            _sha256_file(path) == digest || error("proposal-stage parquet changed")
        elseif isfile(path)
            _sha256_file(path) == digest || error("refusing to replace proposal-stage parquet")
        else
            mkpath(dirname(path))
            mv(candidate, path)
        end
        return digest, bytes
    end
end

function _load_contract()
    for path in (
        EXECUTION_LOCK_PATH,
        PREDECISION_COMPUTATION_LOCK_PATH,
        PREDECISION_RESULT_SEAL_PATH,
        PREDECISION_RESULT_MANIFEST_PATH,
        PREDECISION_STAGE_MANIFEST_PATH,
        LOCAL_PREDECISION_STAGE_MANIFEST_PATH,
        SELECTION_PATH,
        ORIGIN_PATH,
        MASTER_MANIFEST_PATH,
    )
        isfile(path) || error("required proposal-stage input is absent: $(relpath(path, REPOSITORY_ROOT))")
    end
    lock = TOML.parsefile(EXECUTION_LOCK_PATH)
    lock["status"] == "LOCKED_PROPOSAL_EXECUTION" || error("proposal execution is not locked")
    lock["historical_proposal_return_access_permitted"] === true ||
        error("proposal access is not permitted")
    lock["historical_evaluation_return_access_permitted"] === false ||
        error("proposal lock permits evaluation access")
    lock["failed_universe_cell_proposal_access_permitted"] === false ||
        error("proposal lock permits access for a failed universe cell")
    _sha256_file(PREDECISION_RESULT_SEAL_PATH) ==
        EXPECTED_PREDECISION_RESULT_SEAL_SHA256 ||
        error("predecision computation result seal changed")
    result_seal = TOML.parsefile(PREDECISION_RESULT_SEAL_PATH)
    result_seal["status"] == "SEALED_PREDECISION_COMPUTATION_RESULT" ||
        error("predecision computation result is not sealed")
    result_seal["historical_proposal_or_evaluation_return_access_permitted"] === false ||
        error("predecision result seal crossed the postdecision boundary")
    lock["predecision_computation_result_seal_sha256"] ==
        _sha256_file(PREDECISION_RESULT_SEAL_PATH) ||
        error("proposal lock is not bound to predecision computation result seal")
    lock["predecision_computation_lock_sha256"] ==
        _sha256_file(PREDECISION_COMPUTATION_LOCK_PATH) ||
        error("proposal lock is not bound to predecision computation lock")
    lock["predecision_result_manifest_sha256"] ==
        _sha256_file(PREDECISION_RESULT_MANIFEST_PATH) ||
        error("proposal lock is not bound to predecision result manifest")
    sealed = Dict{String,String}(lock["sealed_file_sha256"])
    for (relative, digest) in sealed
        _sha256_file(joinpath(REPOSITORY_ROOT, relative)) == digest ||
            error("proposal-execution sealed file changed: $relative")
    end
    return (;
        lock,
        result = TOML.parsefile(PREDECISION_RESULT_MANIFEST_PATH),
        pre_stage = TOML.parsefile(PREDECISION_STAGE_MANIFEST_PATH),
        local_pre_stage = TOML.parsefile(LOCAL_PREDECISION_STAGE_MANIFEST_PATH),
        selections = TOML.parsefile(SELECTION_PATH),
        origins = _csv_rows(ORIGIN_PATH),
        master = TOML.parsefile(MASTER_MANIFEST_PATH),
    )
end

function _load_cells(contract)
    result_cells = Dict(Int(cell["cell_index"]) => cell for cell in contract.result["cells"])
    stage_cells = Dict(Int(cell["cell_index"]) => cell for cell in contract.local_pre_stage["cells"])
    origin_rows = Dict(row["origin_id"] => row for row in contract.origins)
    selection_rows = collect(contract.selections["cells"])
    sort!(selection_rows; by = row -> (String(row["origin_id"]), String(row["universe_id"])))
    cells = ProposalCell[]
    for (index, selection) in enumerate(selection_rows)
        result = result_cells[index]
        stage = stage_cells[index]
        origin = origin_rows[String(selection["origin_id"])]
        permnos = Set(Int(row["permno"]) for row in selection["selected"])
        result["origin_id"] == selection["origin_id"] || error("proposal cell origin changed")
        result["universe_id"] == selection["universe_id"] || error("proposal cell universe changed")
        push!(cells, ProposalCell(
            index,
            String(selection["origin_id"]),
            String(selection["universe_id"]),
            String(result["role"]),
            String(result["universe_status"]),
            Bool(result["universe_gate_passed"]),
            parse(Int, origin["proposal_year"]),
            parse(Int, origin["evaluation_year"]),
            String(selection["decision_date"]),
            permnos,
            String(stage["local_artifact_relative_path"]),
            String(stage["local_artifact_sha256"]),
        ))
    end
    length(cells) == 38 || error("proposal cell denominator changed")
    count(cell -> !cell.gate_passed, cells) == 1 || error("unexpected failed-cell count")
    return cells
end

function _cells_by_permno(cells)
    result = Dict{Int,Vector{Int}}()
    for cell in cells
        cell.gate_passed || continue
        for permno in cell.selected_permnos
            push!(get!(result, permno, Int[]), cell.cell_index)
        end
    end
    return result
end

function _target_rows_and_calendar(file, cells, cells_by_permno, proposal_years)
    targeted = TargetRow[]
    calendars = Dict(year => Set{String}() for year in proposal_years)
    permno_cursor = Parquet.ColCursor(file, ["permno"])
    date_cursor = Parquet.ColCursor(file, ["date"])
    row_index = 0
    for (permno_record, date_record) in zip(permno_cursor, date_cursor)
        row_index += 1
        isnothing(date_record.value) && error("source date is missing")
        date = String(date_record.value)
        year = parse(Int, date[1:4])
        year in proposal_years && push!(calendars[year], date)
        isnothing(permno_record.value) && continue
        permno = Int(permno_record.value)
        memberships = Int[]
        for cell_index in get(cells_by_permno, permno, Int[])
            cell = cells[cell_index]
            year == cell.proposal_year || continue
            push!(memberships, cell_index)
        end
        isempty(memberships) || push!(targeted, TargetRow(row_index, permno, date, memberships))
    end
    row_index == Parquet.nrows(file) || error("proposal identifier/date cursors lost alignment")
    return targeted, calendars
end

function _extract_chunk(path, expected_sha, expected_rows, cells, cells_by_permno, proposal_years)
    _sha256_file(path) == expected_sha || error("proposal source chunk hash changed")
    file = Parquet.File(path)
    try
        Parquet.nrows(file) == expected_rows || error("proposal source chunk rows changed")
        targeted, calendars = _target_rows_and_calendar(
            file, cells, cells_by_permno, proposal_years,
        )
        target_rows = getfield.(targeted, :row_index)
        values = MaskedReader._materialize_masked_column(file, ["total_return"], target_rows)
        flags = MaskedReader._materialize_masked_column(file, ["return_flag"], target_rows)
        delisting = MaskedReader._materialize_masked_column(file, ["delisting_flag"], target_rows)
        buffers = [SparseProposalBuffer() for _ in cells]
        for (source, value_record, flag_record, delisting_record) in
            zip(targeted, values, flags, delisting)
            isnothing(flag_record) && error("selected proposal return flag is missing")
            isnothing(delisting_record) && error("selected proposal delisting flag is missing")
            flag = String(flag_record)
            delisting_flag = String(delisting_record)
            available = flag == "NA"
            value = if available
                isnothing(value_record) && error("ordinary proposal return is missing")
                converted = Float64(value_record)
                isfinite(converted) && converted >= -1 ||
                    error("ordinary proposal return is invalid")
                converted
            else
                missing
            end
            terminal = !(delisting_flag in ("", "N"))
            for cell_index in source.cell_indices
                cell = cells[cell_index]
                cell.gate_passed || error("failed-cell proposal value was materialized")
                parse(Int, source.date[1:4]) == cell.proposal_year ||
                    error("nonproposal value was materialized")
                cell.proposal_year < cell.evaluation_year || error("proposal/evaluation order changed")
                buffer = buffers[cell_index]
                push!(buffer.permno, source.permno)
                push!(buffer.date, source.date)
                push!(buffer.total_return, value)
                push!(buffer.return_available, available)
                push!(buffer.terminal_delisting, terminal)
                push!(buffer.return_flag, flag)
                push!(buffer.delisting_flag, delisting_flag)
            end
        end
        return ProposalChunk(
            buffers, calendars, expected_rows, length(targeted), expected_sha,
        )
    finally
        close(file)
    end
end

function _append!(target::SparseProposalBuffer, source::SparseProposalBuffer)
    for field in fieldnames(SparseProposalBuffer)
        append!(getfield(target, field), getfield(source, field))
    end
    return target
end

function _extract_all(contract, cells)
    chunks = collect(contract.master["chunks"])
    by_permno = _cells_by_permno(cells)
    years = Set(cell.proposal_year for cell in cells if cell.gate_passed)
    buffers = [SparseProposalBuffer() for _ in cells]
    calendars = Dict(year => Set{String}() for year in years)
    materialized = 0
    source_rows = 0
    worker_count = max(1, Threads.nthreads())
    for first_index in 1:worker_count:length(chunks)
        batch = first_index:min(first_index + worker_count - 1, length(chunks))
        results = Vector{ProposalChunk}(undef, length(batch))
        Threads.@threads :static for local_index in eachindex(batch)
            chunk = chunks[batch[local_index]]
            results[local_index] = _extract_chunk(
                joinpath(MASTER_ROOT, String(chunk["path"])),
                String(chunk["sha256"]),
                Int(chunk["row_count"]),
                cells,
                by_permno,
                years,
            )
        end
        for result in results
            source_rows += result.source_rows
            materialized += result.materialized_rows
            for index in eachindex(cells)
                _append!(buffers[index], result.buffers[index])
            end
            for (year, dates) in result.reference_dates
                union!(calendars[year], dates)
            end
        end
        println(stderr, "v3 proposal extraction completed chunks $(first(batch))-$(last(batch))/$(length(chunks))")
    end
    return (; buffers, calendars, materialized, source_rows)
end

function _combined_table(cell, sparse, calendar)
    pre_path = joinpath(EXPERIMENT_ROOT, cell.predecision_relative_path)
    _sha256_file(pre_path) == cell.predecision_sha256 ||
        error("predecision history artifact changed")
    pre = Tables.columntable(Parquet.Table(pre_path; use_threads = false))
    return _combine_columns(cell, sparse, calendar, pre)
end

function _combine_columns(cell, sparse, calendar, pre)
    pre_permno = Int64.(collect(skipmissing(pre.permno)))
    pre_dates = String.(collect(skipmissing(pre.date)))
    pre_returns = Union{Missing,Float64}[pre.total_return...]
    pre_available = Bool.(collect(skipmissing(pre.return_available)))
    pre_terminal = Bool.(collect(skipmissing(pre.terminal_delisting)))
    pre_flags = String.(collect(skipmissing(pre.return_flag)))
    pre_delisting = String.(collect(skipmissing(pre.delisting_flag)))
    length(pre_permno) == length(pre_dates) == length(pre_returns) ||
        error("predecision history columns do not align")
    proposal_lookup = Dict{Tuple{Int64,String},Int}()
    for index in eachindex(sparse.permno)
        key = (sparse.permno[index], sparse.date[index])
        haskey(proposal_lookup, key) && error("duplicate sparse proposal row")
        proposal_lookup[key] = index
    end
    output_permno = Int64[]
    output_dates = String[]
    output_returns = Union{Missing,Float64}[]
    output_available = Bool[]
    output_terminal = Bool[]
    output_flags = String[]
    output_delisting = String[]
    expected_permnos = sort!(Int64.(collect(cell.selected_permnos)))
    sort!(unique(pre_permno)) == expected_permnos ||
        error("predecision history security identifiers changed")
    pre_sessions = length(pre_permno) ÷ length(expected_permnos)
    pre_sessions * length(expected_permnos) == length(pre_permno) ||
        error("predecision history is not rectangular")
    pre_calendar = String[]
    for (security_index, permno) in enumerate(expected_permnos)
        first_row = (security_index - 1) * pre_sessions + 1
        last_row = security_index * pre_sessions
        rows = first_row:last_row
        all(==(permno), @view pre_permno[rows]) ||
            error("predecision history security rows are not contiguous")
        security_calendar = pre_dates[rows]
        if security_index == 1
            pre_calendar = copy(security_calendar)
            issorted(pre_calendar) && allunique(pre_calendar) ||
                error("predecision history calendar is not canonical")
        else
            security_calendar == pre_calendar ||
                error("predecision history security calendars differ")
        end
        append!(output_permno, @view pre_permno[rows])
        append!(output_dates, @view pre_dates[rows])
        append!(output_returns, @view pre_returns[rows])
        append!(output_available, @view pre_available[rows])
        append!(output_terminal, @view pre_terminal[rows])
        append!(output_flags, @view pre_flags[rows])
        append!(output_delisting, @view pre_delisting[rows])
        terminal_seen = any(@view pre_terminal[rows])
        for date in calendar
            key = (Int64(permno), date)
            push!(output_permno, permno)
            push!(output_dates, date)
            if haskey(proposal_lookup, key)
                index = proposal_lookup[key]
                terminal_seen && error("observed proposal row follows terminal delisting")
                push!(output_returns, sparse.total_return[index])
                push!(output_available, sparse.return_available[index])
                push!(output_terminal, sparse.terminal_delisting[index])
                push!(output_flags, sparse.return_flag[index])
                push!(output_delisting, sparse.delisting_flag[index])
                sparse.terminal_delisting[index] && (terminal_seen = true)
            else
                push!(output_returns, missing)
                push!(output_available, false)
                push!(output_terminal, false)
                push!(output_flags, terminal_seen ? "POST_TERMINAL_CASH" : "ABSENT")
                push!(output_delisting, "N")
            end
        end
    end
    return (;
        permno = output_permno,
        date = output_dates,
        total_return = output_returns,
        return_available = output_available,
        terminal_delisting = output_terminal,
        return_flag = output_flags,
        delisting_flag = output_delisting,
    )
end

function proposal_leakage_sentinel()
    return mktempdir() do directory
        path = joinpath(directory, "proposal-sentinel.parquet")
        Parquet.write_parquet(path, (;
            permno = Int64[10, 10, 10, 20, 20, 20],
            date = ["2000-01-03", "2001-01-03", "2002-01-03", "2000-01-03", "2001-01-03", "2002-01-03"],
            total_return = [NaN, 0.01, Inf, NaN, -0.02, -Inf],
            return_flag = ["X", "NA", "FORBIDDEN", "X", "NA", "FORBIDDEN"],
            delisting_flag = ["X", "N", "FORBIDDEN", "X", "N", "FORBIDDEN"],
        ))
        cells = [
            ProposalCell(1, "O", "u", "primary", "PASSED", true, 2001, 2002, "2000-12-31", Set([10]), "", ""),
            ProposalCell(2, "O", "f", "replication", "FAILED", false, 2001, 2002, "2000-12-31", Set([20]), "", ""),
        ]
        result = _extract_chunk(
            path, _sha256_file(path), 6, cells, _cells_by_permno(cells), Set([2001]),
        )
        length(result.buffers[1].total_return) == 1 || error("sentinel proposal row missing")
        isempty(result.buffers[2].total_return) || error("failed-cell proposal value materialized")
        only(result.buffers[1].total_return) == 0.01 || error("proposal sentinel changed")
        return Dict{String,Any}(
            "status" => "SYNTHETIC_PROPOSAL_MASK_PASSED",
            "proposal_rows_materialized" => 1,
            "failed_cell_rows_materialized" => 0,
            "evaluation_rows_inspected_materialized_or_used" => 0,
            "historical_values_accessed" => false,
        )
    end
end

function stage_proposal_returns(; check = false)
    contract = _load_contract()
    cells = _load_cells(contract)
    extraction = _extract_all(contract, cells)
    extraction.source_rows == Int(contract.master["retained_master_rows"]) ||
        error("proposal identifier/date scan omitted source rows")
    public_cells = Dict{String,Any}[]
    local_cells = Dict{String,Any}[]
    hashes = Dict{String,String}()
    for cell in cells
        calendar = sort!(collect(extraction.calendars[cell.proposal_year]))
        isempty(calendar) && error("proposal reference calendar is empty")
        public = Dict{String,Any}(
            "cell_index" => cell.cell_index,
            "origin_id" => cell.origin_id,
            "universe_id" => cell.universe_id,
            "role" => cell.role,
            "universe_status" => cell.universe_status,
            "universe_gate_passed" => cell.gate_passed,
            "proposal_year" => cell.proposal_year,
            "evaluation_year" => cell.evaluation_year,
            "reference_calendar_sessions" => length(calendar),
            "reference_calendar_first_date" => first(calendar),
            "reference_calendar_last_date" => last(calendar),
            "reference_calendar_sha256" => _sha256_text(join(calendar, '\n')),
            "proposal_access_permitted" => cell.gate_passed,
            "proposal_values_materialized" => cell.gate_passed ?
                length(extraction.buffers[cell.cell_index].total_return) : 0,
            "evaluation_values_inspected_materialized_or_used" => 0,
            "return_values_included" => false,
            "licensed_identifiers_included" => false,
        )
        local_cell = copy(public)
        if cell.gate_passed
            table = _combined_table(cell, extraction.buffers[cell.cell_index], calendar)
            relative = joinpath("local_data", "proposal", "cell-$(lpad(cell.cell_index, 3, '0')).parquet")
            digest, bytes = _install_parquet(joinpath(EXPERIMENT_ROOT, relative), table; check)
            hashes[relative] = digest
            public["local_artifact_relative_path"] = relative
            public["local_artifact_sha256"] = digest
            public["local_artifact_bytes"] = bytes
            public["combined_row_count"] = length(table.permno)
            local_cell = copy(public)
            local_cell["return_values_included"] = true
            local_cell["licensed_identifiers_included"] = true
        else
            public["failure_code"] = "UNIVERSE_GATE_FAILED"
            public["local_artifact_relative_path"] = ""
            public["local_artifact_sha256"] = ""
            public["local_artifact_bytes"] = 0
            public["combined_row_count"] = 0
            local_cell = copy(public)
        end
        push!(public_cells, public)
        push!(local_cells, local_cell)
    end
    common = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-stage-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "PROPOSAL_RETURNS_STAGED",
        "language" => "Julia",
        "cell_count" => 38,
        "accessed_cell_count" => 37,
        "failed_universe_cells_retained_without_access" => 1,
        "identifier_date_rows_scanned" => extraction.source_rows,
        "unique_proposal_source_rows_materialized" => extraction.materialized,
        "identifier_date_mask_frozen_before_return_cursor" => true,
        "masked_column_mechanics" => "Predecision Access Amendment 002",
        "evaluation_values_inspected" => 0,
        "evaluation_values_materialized" => 0,
        "evaluation_values_used" => 0,
        "proposal_execution_lock_sha256" => _sha256_file(EXECUTION_LOCK_PATH),
        "predecision_computation_result_seal_sha256" =>
            _sha256_file(PREDECISION_RESULT_SEAL_PATH),
        "predecision_result_manifest_sha256" => _sha256_file(PREDECISION_RESULT_MANIFEST_PATH),
        "local_artifact_count" => length(hashes),
    )
    public_payload = copy(common)
    public_payload["return_values_included"] = false
    public_payload["licensed_identifiers_included"] = false
    public_payload["public_promotion_permitted"] = true
    public_payload["cells"] = public_cells
    public_text = _toml_text(public_payload)
    local_payload = copy(common)
    local_payload["return_values_included"] = true
    local_payload["licensed_identifiers_included"] = true
    local_payload["public_promotion_permitted"] = false
    local_payload["public_manifest_sha256"] = _sha256_text(public_text)
    local_payload["local_artifact_sha256"] = hashes
    local_payload["cells"] = local_cells
    local_text = _toml_text(local_payload)
    if check
        read(PUBLIC_STAGE_MANIFEST_PATH, String) == public_text || error("public proposal stage changed")
        read(LOCAL_STAGE_MANIFEST_PATH, String) == local_text || error("local proposal stage changed")
    else
        _write_new_or_identical(PUBLIC_STAGE_MANIFEST_PATH, public_text)
        _write_new_or_identical(LOCAL_STAGE_MANIFEST_PATH, local_text)
    end
    println("V3_PROPOSAL_STAGE_PASSED")
    println("proposal-accessed cells: 37/38")
    println("evaluation values inspected/materialized/used: 0")
    return public_payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    stage_proposal_returns(; check = "--check" in args)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    StageFinancialStrategyLibraryPanelV3ProposalReturns.main()
end
