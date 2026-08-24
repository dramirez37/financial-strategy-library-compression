"""
    encode_exact_rational(value)

Return the canonical, lossless `numerator//denominator` representation used by
cross-language theorem fixtures.
"""
function encode_exact_rational(value::Rational)
    exact = exact_rational(value)
    return string(numerator(exact), "//", denominator(exact))
end

"""
    write_exact_matrix(io, matrix)

Write a rational matrix as deterministic tab-separated canonical rational
tokens.  The function performs no floating-point conversion.
"""
function write_exact_matrix(io::IO, matrix::AbstractMatrix{<:Rational})
    for row_index in axes(matrix, 1)
        tokens = [
            encode_exact_rational(matrix[row_index, column_index])
            for column_index in axes(matrix, 2)
        ]
        println(io, join(tokens, '\t'))
    end
    return nothing
end

"""
    read_exact_matrix(io)

Read the deterministic tab-separated format produced by
`write_exact_matrix`, returning `Matrix{ExactRational}`.  Empty input, blank
rows, and ragged matrices are rejected.
"""
function read_exact_matrix(io::IO)
    rows = Vector{Vector{ExactRational}}()
    for (line_number, line) in enumerate(eachline(io))
        isempty(strip(line)) &&
            throw(ArgumentError("blank row at line $line_number in exact matrix"))
        push!(rows, ExactRational[exact_rational(token) for token in split(line, '\t')])
    end
    isempty(rows) && throw(ArgumentError("an exact matrix artifact cannot be empty"))
    column_count = length(first(rows))
    column_count > 0 || throw(ArgumentError("an exact matrix must have at least one column"))
    all(row -> length(row) == column_count, rows) ||
        throw(DimensionMismatch("an exact matrix artifact cannot have ragged rows"))

    result = Matrix{ExactRational}(undef, length(rows), column_count)
    for row_index in eachindex(rows), column_index in 1:column_count
        result[row_index, column_index] = rows[row_index][column_index]
    end
    return result
end
