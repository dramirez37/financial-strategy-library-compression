module JournalCompressionExactCLI

using StrategyInnovation

export main


function _usage_error(message)
    throw(
        ArgumentError(
            message * "\nusage: solve_journal_compression_instance.jl " *
            "INSTANCE.toml [--algorithm dp|enumeration] [--all-ties] " *
            "[--maximum-ties N] [--maximum-optional-strategies N] " *
            "[--output CERTIFICATE.toml]",
        ),
    )
end


function _parse_arguments(args)
    input_path = nothing
    output_path = nothing
    algorithm = :dp
    retain_all_ties = false
    maximum_ties = 100_000
    maximum_optional_strategies = 24
    index = 1
    while index <= length(args)
        token = args[index]
        if token == "--algorithm"
            index < length(args) || _usage_error("--algorithm needs a value")
            value = args[index + 1]
            value in ("dp", "enumeration") ||
                _usage_error("--algorithm must be dp or enumeration")
            algorithm = Symbol(value)
            index += 2
        elseif token == "--all-ties"
            retain_all_ties = true
            index += 1
        elseif token == "--maximum-ties"
            index < length(args) || _usage_error("--maximum-ties needs a value")
            maximum_ties = parse(Int, args[index + 1])
            maximum_ties > 0 || _usage_error("--maximum-ties must be positive")
            index += 2
        elseif token == "--maximum-optional-strategies"
            index < length(args) ||
                _usage_error("--maximum-optional-strategies needs a value")
            maximum_optional_strategies = parse(Int, args[index + 1])
            0 <= maximum_optional_strategies <= 62 || _usage_error(
                "--maximum-optional-strategies must be in 0:62",
            )
            index += 2
        elseif token == "--output"
            index < length(args) || _usage_error("--output needs a path")
            output_path = args[index + 1]
            index += 2
        elseif startswith(token, "--")
            _usage_error("unknown option: $token")
        elseif isnothing(input_path)
            input_path = token
            index += 1
        else
            _usage_error("unexpected positional argument: $token")
        end
    end
    isnothing(input_path) && _usage_error("an input instance path is required")
    return (
        input_path = String(input_path),
        output_path = isnothing(output_path) ? nothing : String(output_path),
        algorithm,
        retain_all_ties,
        maximum_ties,
        maximum_optional_strategies,
    )
end


"""Read one serialized instance and emit a checked exact TOML certificate."""
function main(args = ARGS; output::IO = stdout)
    options = _parse_arguments(args)
    instance = open(options.input_path, "r") do io
        read_journal_compression_instance(io)
    end
    retain_all_ties = options.retain_all_ties ||
                      instance.tie_handling.mode == :complete
    result = if options.algorithm == :dp
        solve_journal_compression_dp(
            instance;
            retain_all_ties,
            maximum_ties = options.maximum_ties,
        )
    else
        solve_journal_compression_enumeration(
            instance;
            retain_all_ties,
            maximum_ties = options.maximum_ties,
            maximum_optional_strategies =
                options.maximum_optional_strategies,
        )
    end
    certificate = serialize_journal_exact_solution(result)
    if isnothing(options.output_path)
        write(output, certificate)
    else
        open(options.output_path, "w") do io
            write(io, certificate)
        end
    end
    return result
end


if abspath(PROGRAM_FILE) == @__FILE__
    try
        main()
    catch error
        showerror(stderr, error)
        println(stderr)
        exit(1)
    end
end

end
