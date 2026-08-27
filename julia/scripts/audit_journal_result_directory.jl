module JournalExactnessAuditCLI

using StrategyInnovation
using TOML

export main


function _usage_error(message)
    throw(
        ArgumentError(
            message * "\nusage: audit_journal_result_directory.jl RESULT_DIRECTORY",
        ),
    )
end


"""
Audit saved manifests, hashes, method certificates, exact burdens, and original-
instance feasibility without invoking enumeration, DP, HiGHS, or any writer.
"""
function main(args = ARGS; output::IO = stdout)
    length(args) == 1 || _usage_error("exactly one result directory is required")
    startswith(args[1], "--") && _usage_error("unknown option: $(args[1])")
    audit = audit_journal_result_directory(args[1])
    TOML.print(
        output,
        journal_exactness_directory_audit_certificate(audit);
        sorted = true,
    )
    return audit
end


if abspath(PROGRAM_FILE) == @__FILE__
    try
        audit = main()
        exit(audit.passed ? 0 : 1)
    catch error
        showerror(stderr, error)
        println(stderr)
        exit(1)
    end
end

end
