module FinancialPanelParquet

using Parquet
using SHA: sha256
using Tables

export atomic_write_parquet,
       parquet_columns,
       parquet_row_count,
       sha256_file,
       validate_parquet

sha256_file(path::AbstractString) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function parquet_columns(path::AbstractString; use_threads::Bool = false)
    table = Parquet.read_parquet(path; use_threads)
    columns = Tables.columntable(table)
    return NamedTuple{propertynames(columns)}(Tuple(collect(column) for column in columns))
end

function parquet_row_count(columns::NamedTuple)
    isempty(propertynames(columns)) && return 0
    lengths = unique(length(column) for column in columns)
    length(lengths) == 1 || error("Parquet columns do not have a common row count")
    return only(lengths)
end

parquet_row_count(path::AbstractString) = parquet_row_count(parquet_columns(path))

function validate_parquet(
    path::AbstractString;
    expected_columns,
    expected_rows::Union{Nothing,Integer} = nothing,
)
    isfile(path) || error("Parquet artifact is absent: $path")
    columns = parquet_columns(path)
    propertynames(columns) == Tuple(Symbol.(expected_columns)) || error(
        "Parquet schema differs for $path",
    )
    rows = parquet_row_count(columns)
    isnothing(expected_rows) || rows == expected_rows || error(
        "Parquet row count differs for $path: expected $expected_rows, found $rows",
    )
    return columns
end

function atomic_write_parquet(
    path::AbstractString,
    columns::NamedTuple;
    replace::Bool = false,
)
    mkpath(dirname(path))
    parquet_row_count(columns)
    temporary = path * ".tmp.$(getpid()).$(Threads.threadid())"
    isfile(temporary) && rm(temporary; force = true)
    try
        Parquet.write_parquet(temporary, columns; compression_codec = "SNAPPY")
        restored = validate_parquet(
            temporary;
            expected_columns = propertynames(columns),
            expected_rows = parquet_row_count(columns),
        )
        propertynames(restored) == propertynames(columns) || error(
            "Parquet round-trip schema differs",
        )
        mv(temporary, path; force = replace)
    finally
        isfile(temporary) && rm(temporary; force = true)
    end
    return path
end

end
