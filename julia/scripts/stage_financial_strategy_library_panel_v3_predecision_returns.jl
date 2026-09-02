module StageFinancialStrategyLibraryPanelV3PredecisionReturns

using Parquet
using SHA: sha256
using TOML

export CellSpecification,
       ChunkExtraction,
       StageBuffer,
       sentinel_leakage_test,
       stage_predecision_returns,
       target_ranges

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
const DESIGN_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK.toml")
const AMENDMENT_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_AMENDMENT_001_LOCK.toml")
const EXTRACTOR_LOCK_001_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_EXTRACTOR_LOCK.toml")
const EXTRACTOR_LOCK_002_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_EXTRACTOR_LOCK_002.toml")
const ACCESS_AMENDMENT_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PREDECISION_ACCESS_AMENDMENT_002_LOCK.toml")
const EXTRACTOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_EXTRACTOR_LOCK_003.toml")
const SELECTION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "universe_census",
    "UNIVERSE_SELECTIONS.toml",
)
const SOURCE_CENSUS_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "source_census",
    "SOURCE_CENSUS_MANIFEST.toml",
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
const LOCAL_STAGE_ROOT = joinpath(EXPERIMENT_ROOT, "local_data", "predecision")
const LOCAL_STAGE_MANIFEST_PATH = joinpath(
    LOCAL_STAGE_ROOT,
    "PREDECISION_STAGE_LOCAL_MANIFEST.toml",
)
const PUBLIC_STAGE_ROOT = joinpath(EXPERIMENT_ROOT, "predecision_stage")
const PUBLIC_STAGE_MANIFEST_PATH = joinpath(
    PUBLIC_STAGE_ROOT,
    "PREDECISION_STAGE_MANIFEST.toml",
)

const IDENTIFIER_DATE_COLUMNS = [["permno"], ["date"]]
const RETURN_COLUMNS = [["total_return"], ["return_flag"], ["delisting_flag"]]
const EXPECTED_AMENDMENT_LOCK_SHA256 =
    "6aaa1cce4c01066ab66c5f371993e326a0e9ec0a469d636731eb506c6e3e5c77"

"A frozen origin-by-universe extraction cell."
struct CellSpecification
    cell_index::Int
    origin_id::String
    universe_id::String
    instrument_class::String
    role::String
    status::String
    formation_start_year::Int
    compression_decision_year::Int
    proposal_year::Int
    evaluation_year::Int
    start_date::String
    decision_date::String
    selected_permnos::Set{Int}
    expected_sessions::Int
end

"The licensed rows staged for one origin-by-universe cell."
mutable struct StageBuffer
    permno::Vector{Int64}
    date::Vector{String}
    total_return::Vector{Float64}
    return_available::Vector{Bool}
    terminal_delisting::Vector{Bool}
    return_flag::Vector{String}
    delisting_flag::Vector{String}
end

StageBuffer() = StageBuffer(
    Int64[],
    String[],
    Float64[],
    Bool[],
    Bool[],
    String[],
    String[],
)

"The bounded result of extracting one sealed source chunk."
struct ChunkExtraction
    cell_buffers::Vector{StageBuffer}
    identifier_date_rows_scanned::Int
    return_rows_materialized::Int
    exact_target_range_count::Int
    maximum_materialized_date::String
    source_sha256::String
end

struct TargetedSourceRow
    row_index::Int
    permno::Int
    date::String
    cell_indices::Vector{Int}
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
    isempty(lines) && error("empty registry: $(relpath(path, REPOSITORY_ROOT))")
    header = split(first(lines), ',')
    result = Dict{String,String}[]
    for line in Iterators.drop(lines, 1)
        fields = split(line, ','; keepempty = true)
        length(fields) == length(header) || error("registry row width changed")
        push!(result, Dict(String(key) => String(value) for (key, value) in zip(header, fields)))
    end
    return result
end

function _directory_aggregate(hashes)
    canonical = join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    )
    return _sha256_text(canonical)
end

function _atomic_write_new_or_identical(path, content)
    if isfile(path)
        read(path, String) == content || error(
            "refusing to replace a nonidentical artifact: $(relpath(path, REPOSITORY_ROOT))",
        )
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

function _check_text(path, content)
    isfile(path) || error("staged artifact is absent: $(relpath(path, REPOSITORY_ROOT))")
    read(path, String) == content || error(
        "staged artifact changed: $(relpath(path, REPOSITORY_ROOT))",
    )
    return path
end

function _load_contract()
    for path in (
        CONFIG_PATH,
        DESIGN_LOCK_PATH,
        AMENDMENT_LOCK_PATH,
        EXTRACTOR_LOCK_001_PATH,
        EXTRACTOR_LOCK_002_PATH,
        ACCESS_AMENDMENT_LOCK_PATH,
        EXTRACTOR_LOCK_PATH,
        SELECTION_PATH,
        SOURCE_CENSUS_MANIFEST_PATH,
        MASTER_MANIFEST_PATH,
        ORIGIN_PATH,
    )
        isfile(path) || error("required v3 staging input is absent: $(relpath(path, REPOSITORY_ROOT))")
    end
    config = TOML.parsefile(CONFIG_PATH)
    design_lock = TOML.parsefile(DESIGN_LOCK_PATH)
    amendment_lock = TOML.parsefile(AMENDMENT_LOCK_PATH)
    extractor_lock = TOML.parsefile(EXTRACTOR_LOCK_PATH)
    extractor_lock_001 = TOML.parsefile(EXTRACTOR_LOCK_001_PATH)
    extractor_lock_002 = TOML.parsefile(EXTRACTOR_LOCK_002_PATH)
    access_amendment_lock = TOML.parsefile(ACCESS_AMENDMENT_LOCK_PATH)
    census_manifest = TOML.parsefile(SOURCE_CENSUS_MANIFEST_PATH)
    master_manifest = TOML.parsefile(MASTER_MANIFEST_PATH)

    config["language"] == "Julia" || error("v3 main language is not Julia")
    config["v3_outcomes_opened"] === false || error("v3 outcome lock is not active")
    design_lock["status"] == "LOCKED_PREDECISION" || error("v3 base design is not locked")
    design_lock["historical_predecision_return_access_permitted"] === true ||
        error("base design lock does not permit predecision return access")
    design_lock["historical_proposal_or_evaluation_return_access_permitted"] === false ||
        error("base design lock permits forbidden postdecision access")
    amendment_lock["status"] == "LOCKED_PREDECISION_IMPLEMENTATION" ||
        error("v3 predecision implementation amendment is not locked")
    _sha256_file(AMENDMENT_LOCK_PATH) == EXPECTED_AMENDMENT_LOCK_SHA256 ||
        error("current implementation amendment lock hash changed")
    amendment_lock["predecision_access_authority_model"] ==
        "base_eligibility_plus_current_amendment_plus_extractor_lock" ||
        error("predecision access authority model changed")
    amendment_lock["base_design_lock_alone_authorizes_return_access"] === false ||
        error("base design lock alone was allowed to authorize return access")
    amendment_lock["current_amendment_lock_required_for_return_access"] === true ||
        error("current implementation amendment is not required for return access")
    amendment_lock["date_aware_extractor_lock_required_for_return_access"] === true ||
        error("date-aware extractor lock is not required for return access")
    amendment_lock["effective_historical_predecision_return_access_permitted"] === false ||
        error("implementation amendment claims effective return access before extractor seal")
    amendment_lock["historical_predecision_return_access_permitted"] === false ||
        error("implementation amendment unexpectedly grants return access")
    amendment_lock["historical_proposal_or_evaluation_return_access_permitted"] === false ||
        error("implementation amendment permits forbidden postdecision access")
    extractor_lock["status"] == "LOCKED_PREDECISION_EXTRACTOR_003" ||
        error("v3 outcome-safe extractor is not locked")
    extractor_lock["previous_extractor_lock_sha256"] ==
        _sha256_file(EXTRACTOR_LOCK_002_PATH) ||
        error("extractor 003 is not bound to extractor lock 002")
    extractor_lock["extractor_lock_001_sha256"] == _sha256_file(EXTRACTOR_LOCK_001_PATH) ||
        error("extractor 003 is not bound to extractor lock 001")
    extractor_lock["access_amendment_002_lock_sha256"] ==
        _sha256_file(ACCESS_AMENDMENT_LOCK_PATH) ||
        error("extractor 003 is not bound to access amendment 002")
    extractor_lock["predecision_values_accessed_before_003"] === true ||
        error("optimized extractor lock conceals prior authorized predecision access")
    extractor_lock["prior_access_was_authorized"] === true ||
        error("optimized extractor lock does not acknowledge prior authority")
    extractor_lock["change_scope"] ==
        "performance_only_access_mechanics_no_scientific_design_change" ||
        error("extractor 003 change scope is not the frozen access amendment")
    extractor_lock["proposal_values_inspected_materialized_or_used_before_003"] === false ||
        error("optimized extractor lock reports prior proposal access")
    extractor_lock["evaluation_values_inspected_materialized_or_used_before_003"] === false ||
        error("optimized extractor lock reports prior evaluation access")
    extractor_lock["historical_predecision_return_access_permitted"] === true ||
        error("extractor lock does not permit predecision return access")
    extractor_lock["historical_proposal_or_evaluation_return_access_permitted"] === false ||
        error("extractor lock permits forbidden postdecision access")
    extractor_lock["implementation_amendment_lock_sha256"] ==
        _sha256_file(AMENDMENT_LOCK_PATH) ||
        error("extractor lock is not bound to the current implementation amendment")
    sealed_hashes = Dict{String,String}(extractor_lock["sealed_file_sha256"])
    for relative in sort!(collect(keys(sealed_hashes)))
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("extractor-sealed file is absent: $relative")
        _sha256_file(path) == sealed_hashes[relative] ||
            error("extractor-sealed file changed: $relative")
    end
    extractor_canonical = join(
        ("$relative\0$(sealed_hashes[relative])\n" for relative in sort!(collect(keys(sealed_hashes)))),
    )
    _sha256_text(extractor_canonical) == extractor_lock["extractor_aggregate_sha256"] ||
        error("extractor seal aggregate does not verify")

    selection_hash = _sha256_file(SELECTION_PATH)
    selection_hash == String(design_lock["local_universe_selection_sha256"]) ||
        error("locked local universe selection changed")
    selection_hash == String(census_manifest["local_selection_sha256"]) ||
        error("source-census selection binding changed")
    master_manifest_hash = _sha256_file(MASTER_MANIFEST_PATH)
    master_manifest_hash == String(config["source"]["historical_development_manifest_sha256"]) ||
        error("sealed v2 master manifest changed")
    master_manifest["retained_master_rows"] ==
        sum(Int(chunk["row_count"]) for chunk in master_manifest["chunks"]) ||
        error("sealed v2 master row count does not reconcile")

    extractor_lock_001["effective_historical_predecision_return_access_permitted"] === true ||
        error("extractor lock 001 did not authorize the interrupted predecision access")
    extractor_lock_002["effective_historical_predecision_return_access_permitted"] === true ||
        error("extractor lock 002 did not authorize the interrupted predecision access")
    access_amendment_lock["status"] == "LOCKED_PREDECISION_ACCESS_AMENDMENT_002" ||
        error("predecision access amendment 002 is not locked")
    access_amendment_lock["scientific_design_changed"] === false ||
        error("predecision access amendment changes the scientific design")

    return (; config, design_lock, amendment_lock, extractor_lock, extractor_lock_001,
        extractor_lock_002, access_amendment_lock, census_manifest, master_manifest,
        selection_hash, master_manifest_hash)
end

function _origin_rows()
    result = Dict{String,NamedTuple}()
    for row in _csv_rows(ORIGIN_PATH)
        origin_id = row["origin_id"]
        result[origin_id] = (;
            origin_id,
            formation_start_year = parse(Int, row["formation_start_year"]),
            compression_decision_year = parse(Int, row["compression_decision_year"]),
            proposal_year = parse(Int, row["proposal_year"]),
            evaluation_year = parse(Int, row["evaluation_year"]),
        )
    end
    return result
end

function _load_cells()
    selections = TOML.parsefile(SELECTION_PATH)
    selections["outcome_values_accessed"] === false ||
        error("universe selection artifact claims outcome access")
    origins = _origin_rows()
    rows = collect(selections["cells"])
    sort!(rows; by = row -> (String(row["origin_id"]), String(row["universe_id"])))
    cells = CellSpecification[]
    for (cell_index, row) in enumerate(rows)
        origin_id = String(row["origin_id"])
        haskey(origins, origin_id) || error("unregistered origin in universe selections")
        origin = origins[origin_id]
        decision_year = Int(row["decision_year"])
        decision_year == origin.compression_decision_year ||
            error("universe selection decision year changed")
        decision_date = String(row["decision_date"])
        startswith(decision_date, "$(decision_year)-") ||
            error("universe selection decision date changed year")
        permnos = Set(Int(selected["permno"]) for selected in row["selected"])
        length(permnos) == Int(row["selected_count"]) ||
            error("duplicate identifier in locked universe selection")
        push!(cells, CellSpecification(
            cell_index,
            origin_id,
            String(row["universe_id"]),
            String(row["instrument_class"]),
            String(row["role"]),
            String(row["status"]),
            origin.formation_start_year,
            decision_year,
            origin.proposal_year,
            origin.evaluation_year,
            "$(origin.formation_start_year)-01-01",
            decision_date,
            permnos,
            Int(row["expected_predecision_sessions"]),
        ))
    end
    length(cells) == 38 || error("v3 staging does not have 38 registered cells")
    return cells
end

function _cells_by_permno(cells)
    result = Dict{Int,Vector{Int}}()
    for cell in cells, permno in cell.selected_permnos
        push!(get!(result, permno, Int[]), cell.cell_index)
    end
    for indices in values(result)
        sort!(indices)
    end
    return result
end

"Convert sorted row indices into exact contiguous ranges without filling gaps."
function target_ranges(row_indices::AbstractVector{<:Integer})
    isempty(row_indices) && return UnitRange{Int}[]
    issorted(row_indices) || throw(ArgumentError("target row indices are not sorted"))
    allunique(row_indices) || throw(ArgumentError("target row indices are not unique"))
    result = UnitRange{Int}[]
    first_row = Int(first(row_indices))
    last_row = first_row
    for value in Iterators.drop(row_indices, 1)
        row = Int(value)
        if row == last_row + 1
            last_row = row
        else
            push!(result, first_row:last_row)
            first_row = last_row = row
        end
    end
    push!(result, first_row:last_row)
    return result
end

function _targeted_identifier_date_rows(file, cells, cells_by_permno)
    targeted = TargetedSourceRow[]
    permno_cursor = Parquet.ColCursor(file, only(IDENTIFIER_DATE_COLUMNS[1:1]))
    date_cursor = Parquet.ColCursor(file, only(IDENTIFIER_DATE_COLUMNS[2:2]))
    row_index = 0
    for (permno_record, date_record) in zip(permno_cursor, date_cursor)
        row_index += 1
        isnothing(permno_record.value) && continue
        isnothing(date_record.value) && error("sealed master contains a missing date")
        permno = Int(permno_record.value)
        candidate_cells = get(cells_by_permno, permno, nothing)
        isnothing(candidate_cells) && continue
        date = String(date_record.value)
        memberships = Int[]
        for cell_index in candidate_cells
            cell = cells[cell_index]
            cell.start_date <= date <= cell.decision_date || continue
            push!(memberships, cell_index)
        end
        isempty(memberships) || push!(
            targeted,
            TargetedSourceRow(row_index, permno, date, memberships),
        )
    end
    row_index == Parquet.nrows(file) || error("identifier/date column cursors lost alignment")
    return targeted
end

function _append!(target::StageBuffer, source::StageBuffer)
    append!(target.permno, source.permno)
    append!(target.date, source.date)
    append!(target.total_return, source.total_return)
    append!(target.return_available, source.return_available)
    append!(target.terminal_delisting, source.terminal_delisting)
    append!(target.return_flag, source.return_flag)
    append!(target.delisting_flag, source.delisting_flag)
    return target
end

"""
Materialize one projected Parquet field only at frozen source-row indices.

The identifier/date-only pass must finish before this function is called. For
an unmasked row, application code advances the column cursor from its opaque
iterator state and never reads `.value`. Parquet codecs necessarily decompress
physical pages; page decompression is not experiment-level inspection or
materialization of an unmasked row.
"""
function _materialize_masked_column(file, column, target_rows)
    issorted(target_rows) || throw(ArgumentError("masked target rows are not sorted"))
    allunique(target_rows) || throw(ArgumentError("masked target rows are not unique"))
    isempty(target_rows) && return Any[]
    first(target_rows) >= 1 || throw(ArgumentError("masked target row is below one"))
    last(target_rows) <= Parquet.nrows(file) ||
        throw(ArgumentError("masked target row exceeds source row count"))

    cursor = Parquet.ColCursor(file, column)
    iteration = iterate(cursor)
    selected = Any[]
    sizehint!(selected, length(target_rows))
    target_pointer = 1
    for row_index in 1:Parquet.nrows(file)
        isnothing(iteration) && error("projected return cursor ended before the source file")
        if target_pointer <= length(target_rows) && row_index == target_rows[target_pointer]
            # Only this masked branch may inspect a projected field. The
            # unmasked path below touches iterator state only.
            record = first(iteration)
            push!(selected, record.value)
            target_pointer += 1
        end
        state = last(iteration)
        iteration = iterate(cursor, state)
    end
    isnothing(iteration) || error("projected return cursor exceeded the source file")
    target_pointer == length(target_rows) + 1 ||
        error("projected return cursor omitted a masked target row")
    return selected
end

function _extract_chunk(path, expected_sha256, expected_rows, cells, cells_by_permno)
    source_hash = _sha256_file(path)
    source_hash == expected_sha256 || error("sealed source chunk hash changed: $(basename(path))")
    file = Parquet.File(path)
    try
        source_rows = Parquet.nrows(file)
        source_rows == expected_rows || error("sealed source chunk row count changed")

        # This is the hard data-access boundary. Only identifier and ISO date
        # columns exist in the first pass. Return columns are not requested
        # until the exact source-row selection has been frozen below.
        targeted = _targeted_identifier_date_rows(file, cells, cells_by_permno)
        target_rows = [row.row_index for row in targeted]
        ranges = target_ranges(target_rows)
        buffers = [StageBuffer() for _ in cells]
        maximum_date = ""
        # The selection is now immutable. Each projected field gets one
        # forward pass; unmasked rows advance opaque iterator state only.
        return_values = _materialize_masked_column(file, RETURN_COLUMNS[1], target_rows)
        return_flags = _materialize_masked_column(file, RETURN_COLUMNS[2], target_rows)
        delisting_flags = _materialize_masked_column(file, RETURN_COLUMNS[3], target_rows)
        length(return_values) == length(targeted) == length(return_flags) ==
            length(delisting_flags) || error("masked return fields lost alignment")
        for index in eachindex(targeted)
            source = targeted[index]
            value_record = return_values[index]
            flag_record = return_flags[index]
            delisting_record = delisting_flags[index]
            isnothing(value_record) && error("selected predecision return is missing")
            isnothing(flag_record) && error("selected predecision return flag is missing")
            isnothing(delisting_record) && error("selected predecision delisting flag is missing")
            value = Float64(value_record)
            flag = String(flag_record)
            delisting_flag = String(delisting_record)
            terminal_delisting = !(delisting_flag in ("", "N"))
            isfinite(value) || error("selected predecision return is nonfinite")
            value >= -1 || error("selected predecision return is below total loss")
            flag == "NA" || error("selected predecision row is not an ordinary return")
            for cell_index in source.cell_indices
                cell = cells[cell_index]
                source.date <= cell.decision_date ||
                    error("postdecision return membership materialized")
                year = parse(Int, source.date[1:4])
                year < cell.proposal_year || error("proposal return membership materialized")
                year < cell.evaluation_year || error("evaluation return membership materialized")
                buffer = buffers[cell_index]
                push!(buffer.permno, Int64(source.permno))
                push!(buffer.date, source.date)
                push!(buffer.total_return, value)
                push!(buffer.return_available, true)
                push!(buffer.terminal_delisting, terminal_delisting)
                push!(buffer.return_flag, flag)
                push!(buffer.delisting_flag, delisting_flag)
            end
            maximum_date = max(maximum_date, source.date)
        end
        return ChunkExtraction(
            buffers,
            source_rows,
            length(targeted),
            length(ranges),
            maximum_date,
            source_hash,
        )
    finally
        close(file)
    end
end

function _sort_and_validate!(buffer, cell)
    count = length(buffer.permno)
    count == length(buffer.date) == length(buffer.total_return) ==
        length(buffer.return_available) == length(buffer.terminal_delisting) ==
        length(buffer.return_flag) == length(buffer.delisting_flag) ||
        error("staged column lengths do not match")
    expected = length(cell.selected_permnos) * cell.expected_sessions
    count == expected || error(
        "$(cell.origin_id) $(cell.universe_id) staged $count rows, expected $expected",
    )
    order = sortperm(eachindex(buffer.permno); by = index -> (buffer.permno[index], buffer.date[index]))
    buffer.permno .= buffer.permno[order]
    buffer.date .= buffer.date[order]
    buffer.total_return .= buffer.total_return[order]
    buffer.return_available .= buffer.return_available[order]
    buffer.terminal_delisting .= buffer.terminal_delisting[order]
    buffer.return_flag .= buffer.return_flag[order]
    buffer.delisting_flag .= buffer.delisting_flag[order]
    counts = Dict{Int,Int}()
    previous = nothing
    terminal_permnos = Set{Int}()
    for index in eachindex(buffer.permno)
        permno = Int(buffer.permno[index])
        permno in cell.selected_permnos || error("unselected identifier entered staged cell")
        date = buffer.date[index]
        cell.start_date <= date <= cell.decision_date || error("staged date left predecision window")
        key = (permno, date)
        key == previous && error("duplicate staged identifier-date row")
        previous = key
        permno in terminal_permnos && error("staged return follows a terminal delisting flag")
        buffer.return_available[index] || error("selected complete-universe return is unavailable")
        buffer.terminal_delisting[index] ==
            !(buffer.delisting_flag[index] in ("", "N")) ||
            error("terminal-delisting derivation changed")
        buffer.terminal_delisting[index] && push!(terminal_permnos, permno)
        counts[permno] = get(counts, permno, 0) + 1
    end
    Set(keys(counts)) == cell.selected_permnos || error("staged cell omitted a selected identifier")
    all(==(cell.expected_sessions), values(counts)) ||
        error("staged identifier does not have the full predecision calendar")
    return buffer
end

function _write_parquet_candidate(path, buffer)
    Parquet.write_parquet(path, (;
        permno = buffer.permno,
        date = buffer.date,
        total_return = buffer.total_return,
        return_available = buffer.return_available,
        terminal_delisting = buffer.terminal_delisting,
        return_flag = buffer.return_flag,
        delisting_flag = buffer.delisting_flag,
    ))
    return path
end

function _install_or_check_parquet(path, buffer; check)
    mktempdir() do temporary_root
        candidate = joinpath(temporary_root, basename(path))
        _write_parquet_candidate(candidate, buffer)
        candidate_hash = _sha256_file(candidate)
        candidate_bytes = filesize(candidate)
        if check
            isfile(path) || error("staged cell artifact is absent: $(relpath(path, REPOSITORY_ROOT))")
            _sha256_file(path) == candidate_hash || error(
                "staged cell artifact changed: $(relpath(path, REPOSITORY_ROOT))",
            )
        elseif isfile(path)
            _sha256_file(path) == candidate_hash || error(
                "refusing to replace a nonidentical staged cell: $(relpath(path, REPOSITORY_ROOT))",
            )
        else
            mkpath(dirname(path))
            mv(candidate, path)
        end
        return candidate_hash, candidate_bytes
    end
end

function _extract_all_chunks(chunks, cells, cells_by_permno)
    buffers = [StageBuffer() for _ in cells]
    identifier_rows = 0
    materialized_rows = 0
    target_ranges_count = 0
    maximum_date = ""
    source_hashes = Dict{String,String}()
    worker_count = max(1, Threads.nthreads())
    for first_index in 1:worker_count:length(chunks)
        last_index = min(first_index + worker_count - 1, length(chunks))
        batch = first_index:last_index
        println(
            stderr,
            "v3 predecision staging starting chunk batch $first_index-$last_index/$(length(chunks)) " *
            "workers=$worker_count",
        )
        results = Vector{ChunkExtraction}(undef, length(batch))
        Threads.@threads :static for local_index in eachindex(batch)
            chunk_index = batch[local_index]
            chunk = chunks[chunk_index]
            path = joinpath(MASTER_ROOT, String(chunk["path"]))
            results[local_index] = _extract_chunk(
                path,
                String(chunk["sha256"]),
                Int(chunk["row_count"]),
                cells,
                cells_by_permno,
            )
            println(
                stderr,
                "v3 predecision staging extracted chunk $chunk_index/$(length(chunks)) " *
                "materialized=$(results[local_index].return_rows_materialized) " *
                "ranges=$(results[local_index].exact_target_range_count)",
            )
        end
        for (local_index, extraction) in enumerate(results)
            chunk_index = batch[local_index]
            chunk_path = String(chunks[chunk_index]["path"])
            source_hashes[chunk_path] = extraction.source_sha256
            identifier_rows += extraction.identifier_date_rows_scanned
            materialized_rows += extraction.return_rows_materialized
            target_ranges_count += extraction.exact_target_range_count
            maximum_date = max(maximum_date, extraction.maximum_materialized_date)
            for cell_index in eachindex(cells)
                _append!(buffers[cell_index], extraction.cell_buffers[cell_index])
            end
            println(
                stderr,
                "v3 predecision staging completed chunk $chunk_index/$(length(chunks)) " *
                "materialized=$(extraction.return_rows_materialized)",
            )
        end
    end
    return (; buffers, identifier_rows, materialized_rows, target_ranges_count,
        maximum_date, source_hashes)
end

function _complete_source_hashes(chunk_hashes)
    hashes = copy(chunk_hashes)
    for (root, _, files) in walkdir(MASTER_ROOT), file in files
        path = joinpath(root, file)
        relative = relpath(path, MASTER_ROOT)
        haskey(hashes, relative) || (hashes[relative] = _sha256_file(path))
    end
    return hashes
end

"Run an all-synthetic sentinel proving postdecision rows are not inspected or materialized."
function sentinel_leakage_test()
    return mktempdir() do directory
        path = joinpath(directory, "sentinel.parquet")
        Parquet.write_parquet(path, (;
            permno = Int64[10, 10, 10, 10, 20, 20, 20, 20],
            date = [
                "2000-01-03",
                "2000-01-04",
                "2001-01-02",
                "2002-01-02",
                "2000-01-03",
                "2000-01-04",
                "2001-01-02",
                "2002-01-02",
            ],
            total_return = [0.01, -1.0, NaN, -Inf, 0.03, 0.04, Inf, NaN],
            return_flag = ["NA", "NA", "FORBIDDEN", "FORBIDDEN", "NA", "NA", "X", "Y"],
            delisting_flag = ["N", "D", "FORBIDDEN", "FORBIDDEN", "N", "N", "X", "Y"],
        ))
        cells = [CellSpecification(
            1,
            "SENTINEL-O2000",
            "liquid_common_equity",
            "common_equity",
            "primary",
            "PASSED",
            2000,
            2000,
            2001,
            2002,
            "2000-01-01",
            "2000-12-31",
            Set([10, 20]),
            2,
        )]
        extraction = _extract_chunk(
            path,
            _sha256_file(path),
            8,
            cells,
            _cells_by_permno(cells),
        )
        buffer = only(extraction.cell_buffers)
        _sort_and_validate!(buffer, only(cells))
        extraction.identifier_date_rows_scanned == 8 || error("sentinel identifier scan changed")
        extraction.return_rows_materialized == 4 ||
            error("sentinel materialized a postdecision row")
        extraction.exact_target_range_count == 2 || error("sentinel exact target ranges changed")
        extraction.maximum_materialized_date == "2000-01-04" ||
            error("sentinel maximum materialized date crossed the decision")
        maximum(buffer.total_return) <= 0.04 || error("sentinel proposal/evaluation value leaked")
        minimum(buffer.total_return) == -1.0 || error("sentinel exact total loss was not preserved")
        count(identity, buffer.terminal_delisting) == 1 ||
            error("sentinel terminal delisting mask was not preserved")
        alternate_path = joinpath(directory, "sentinel-alternate.parquet")
        Parquet.write_parquet(alternate_path, (;
            permno = Int64[10, 10, 10, 10, 20, 20, 20, 20],
            date = [
                "2000-01-03",
                "2000-01-04",
                "2001-01-02",
                "2002-01-02",
                "2000-01-03",
                "2000-01-04",
                "2001-01-02",
                "2002-01-02",
            ],
            total_return = [0.01, -1.0, -Inf, NaN, 0.03, 0.04, NaN, Inf],
            return_flag = ["NA", "NA", "A", "B", "NA", "NA", "C", "D"],
            delisting_flag = ["N", "D", "A", "B", "N", "N", "C", "D"],
        ))
        alternate = _extract_chunk(
            alternate_path,
            _sha256_file(alternate_path),
            8,
            cells,
            _cells_by_permno(cells),
        )
        alternate_buffer = only(alternate.cell_buffers)
        _sort_and_validate!(alternate_buffer, only(cells))
        buffer.permno == alternate_buffer.permno || error("unmasked values changed identifiers")
        buffer.date == alternate_buffer.date || error("unmasked values changed dates")
        buffer.total_return == alternate_buffer.total_return ||
            error("unmasked values changed materialized returns")
        buffer.return_flag == alternate_buffer.return_flag ||
            error("unmasked values changed materialized return flags")
        buffer.delisting_flag == alternate_buffer.delisting_flag ||
            error("unmasked values changed materialized delisting flags")
        return Dict{String,Any}(
            "status" => "SYNTHETIC_SENTINEL_PASSED",
            "identifier_date_rows_scanned" => 8,
            "return_rows_materialized_after_filter" => 4,
            "postdecision_rows_present_in_source" => 4,
            "postdecision_rows_inspected" => 0,
            "postdecision_rows_materialized" => 0,
            "postdecision_rows_used" => 0,
            "exact_target_range_count" => 2,
            "terminal_delisting_rows_preserved" => 1,
            "exact_negative_one_return_preserved" => true,
            "adversarial_unmasked_variant_count" => 2,
            "masked_outputs_identical_across_unmasked_variants" => true,
            "real_historical_return_values_accessed" => false,
        )
    end
end

function stage_predecision_returns(; check = false)
    contract = _load_contract()
    cells = _load_cells()
    cells_by_permno = _cells_by_permno(cells)
    chunks = collect(contract.master_manifest["chunks"])
    extraction = _extract_all_chunks(chunks, cells, cells_by_permno)
    extraction.identifier_rows == Int(contract.master_manifest["retained_master_rows"]) ||
        error("identifier/date scan did not cover every sealed master row")
    source_hashes = _complete_source_hashes(extraction.source_hashes)
    source_aggregate = _directory_aggregate(source_hashes)
    source_aggregate == String(contract.config["source"]["historical_development_directory_aggregate_sha256"]) ||
        error("sealed v2 master directory aggregate changed")

    public_cells = Dict{String,Any}[]
    local_cells = Dict{String,Any}[]
    staged_memberships = 0
    for (cell_index, (cell, buffer)) in enumerate(zip(cells, extraction.buffers))
        _sort_and_validate!(buffer, cell)
        relative_path = joinpath("local_data", "predecision", "cell-$(lpad(cell_index, 3, '0')).parquet")
        path = joinpath(EXPERIMENT_ROOT, relative_path)
        artifact_hash, artifact_bytes = _install_or_check_parquet(path, buffer; check)
        row_count = length(buffer.permno)
        staged_memberships += row_count
        public = Dict{String,Any}(
            "cell_index" => cell_index,
            "origin_id" => cell.origin_id,
            "universe_id" => cell.universe_id,
            "instrument_class" => cell.instrument_class,
            "role" => cell.role,
            "status" => cell.status,
            "formation_start_year" => cell.formation_start_year,
            "compression_decision_year" => cell.compression_decision_year,
            "decision_date" => cell.decision_date,
            "selected_security_count" => length(cell.selected_permnos),
            "expected_sessions_per_security" => cell.expected_sessions,
            "staged_row_count" => row_count,
            "minimum_staged_date" => minimum(buffer.date),
            "maximum_staged_date" => maximum(buffer.date),
            "local_artifact_relative_path" => relative_path,
            "local_artifact_sha256" => artifact_hash,
            "local_artifact_bytes" => artifact_bytes,
            "proposal_or_evaluation_values_materialized" => 0,
            "terminal_delisting_row_count" => count(identity, buffer.terminal_delisting),
            "return_values_included" => false,
            "licensed_identifiers_included" => false,
        )
        push!(public_cells, public)
        local_cell = copy(public)
        local_cell["selected_permno_count"] = length(cell.selected_permnos)
        local_cell["selected_permno_set_sha256"] = _sha256_text(
            join(sort!(collect(cell.selected_permnos)), ','),
        )
        local_cell["return_values_included"] = true
        local_cell["licensed_identifiers_included"] = true
        push!(local_cells, local_cell)
    end

    common = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-predecision-stage-manifest-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "PREDECISION_RETURNS_STAGED",
        "language" => "Julia",
        "cell_count" => length(cells),
        "local_artifact_count" => length(cells),
        "identifier_date_rows_scanned" => extraction.identifier_rows,
        "return_rows_materialized_after_identifier_date_filter" => extraction.materialized_rows,
        "exact_target_range_count" => extraction.target_ranges_count,
        "staged_cell_row_memberships" => staged_memberships,
        "maximum_return_date_materialized" => extraction.maximum_date,
        "identifier_date_filter_preceded_return_decode" => true,
        "identifier_date_reader" => "aligned Parquet.ColCursor streams",
        "return_reader" =>
            "one projected forward Parquet.ColCursor pass per field with a frozen selected-row mask",
        "unmasked_return_rows" =>
            "cursor state advanced only; application code never inspects .value",
        "parquet_page_decompression_disclosure" =>
            "Parquet codecs physically decompress pages; page decompression is not experiment-level row inspection or materialization",
        "proposal_or_evaluation_values_inspected" => 0,
        "proposal_or_evaluation_values_materialized" => 0,
        "proposal_or_evaluation_values_used" => 0,
        "historical_predecision_return_access_permitted" => true,
        "historical_proposal_or_evaluation_return_access_permitted" => false,
        "source_master_manifest_sha256" => contract.master_manifest_hash,
        "source_master_directory_aggregate_sha256" => source_aggregate,
        "local_universe_selection_sha256" => contract.selection_hash,
        "design_lock_sha256" => _sha256_file(DESIGN_LOCK_PATH),
        "predecision_amendment_lock_sha256" => _sha256_file(AMENDMENT_LOCK_PATH),
        "predecision_extractor_lock_001_sha256" => _sha256_file(EXTRACTOR_LOCK_001_PATH),
        "predecision_extractor_lock_002_sha256" => _sha256_file(EXTRACTOR_LOCK_002_PATH),
        "predecision_access_amendment_002_lock_sha256" =>
            _sha256_file(ACCESS_AMENDMENT_LOCK_PATH),
        "predecision_extractor_lock_sha256" => _sha256_file(EXTRACTOR_LOCK_PATH),
        "staging_script_sha256" => _sha256_file(@__FILE__),
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
    local_payload["cells"] = local_cells
    local_text = _toml_text(local_payload)

    if check
        _check_text(LOCAL_STAGE_MANIFEST_PATH, local_text)
        _check_text(PUBLIC_STAGE_MANIFEST_PATH, public_text)
    else
        _atomic_write_new_or_identical(LOCAL_STAGE_MANIFEST_PATH, local_text)
        _atomic_write_new_or_identical(PUBLIC_STAGE_MANIFEST_PATH, public_text)
    end
    println("V3_PREDECISION_RETURN_STAGE_PASSED")
    println("cells staged: $(length(cells))")
    println("staged cell-row memberships: $staged_memberships")
    println("proposal/evaluation values inspected/materialized/used: 0")
    println("public manifest: $(relpath(PUBLIC_STAGE_MANIFEST_PATH, REPOSITORY_ROOT))")
    return public_payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    stage_predecision_returns(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    StageFinancialStrategyLibraryPanelV3PredecisionReturns.main()
end
