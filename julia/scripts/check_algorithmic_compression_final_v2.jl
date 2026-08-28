module CheckAlgorithmicCompressionFinalV2

include(joinpath(@__DIR__, "audit_algorithmic_compression_final_v2.jl"))
using .AuditAlgorithmicCompressionFinalV2
using SHA: sha256
using TOML

const HISTORICAL_MAKEFILE_SHA256 = Ref("")


function install_historical_makefile_hash!()
    runner = AuditAlgorithmicCompressionFinalV2.AlgorithmicCompressionFinalV2
    lock_module = runner.LockAlgorithmicCompressionDesignV2
    environment = TOML.parsefile(runner._active_environment_path())
    execution_commit = get(environment, "git_commit", "")
    occursin(r"^[0-9a-f]{40}$", execution_commit) || error(
        "recorded benchmark execution commit is malformed",
    )
    lock_text = read(lock_module.AMENDMENT_003_LOCK_PATH, String)
    expected_match = match(
        r"\"Makefile\": \"([0-9a-f]{64})\"",
        lock_text,
    )
    isnothing(expected_match) && error("active benchmark lock omits Makefile")
    expected = only(expected_match.captures)
    historical_text = read(
        `git -C $(lock_module.REPOSITORY_ROOT) show $execution_commit:Makefile`,
        String,
    )
    historical_hash = bytes2hex(sha256(codeunits(historical_text)))
    historical_hash == expected || error(
        "the Makefile at the recorded execution commit does not match the lock",
    )
    HISTORICAL_MAKEFILE_SHA256[] = historical_hash

    @eval AuditAlgorithmicCompressionFinalV2.AlgorithmicCompressionFinalV2.LockAlgorithmicCompressionDesignV2 begin
        function _sha256_file(path)
            if normpath(path) == normpath(joinpath(REPOSITORY_ROOT, "Makefile"))
                return Main.CheckAlgorithmicCompressionFinalV2.HISTORICAL_MAKEFILE_SHA256[]
            end
            return open(path, "r") do io
                bytes2hex(sha256(io))
            end
        end
    end
    return nothing
end


function install_read_only_persistence!()
    @eval AuditAlgorithmicCompressionFinalV2 begin
        function _write_replace(path::AbstractString, text::AbstractString)
            isfile(path) || error(
                "read-only benchmark audit expected a committed artifact: " *
                _relative(path),
            )
            committed = read(path, String)
            committed == text || error(
                "read-only benchmark audit detected artifact drift: " *
                _relative(path),
            )
            return text
        end

        function _write_replace_toml(path, payload)
            io = IOBuffer()
            TOML.print(io, payload; sorted = true)
            return _write_replace(path, String(take!(io)))
        end
    end
    return nothing
end


function main(args = ARGS)
    isempty(args) || error(
        "usage: check_algorithmic_compression_final_v2.jl",
    )
    install_historical_makefile_hash!()
    install_read_only_persistence!()
    Base.invokelatest(AuditAlgorithmicCompressionFinalV2.audit_final_benchmark)
    println(
        "read-only v2 benchmark audit matched every committed generated " *
        "certificate, manifest, and report byte-for-byte",
    )
    return nothing
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    CheckAlgorithmicCompressionFinalV2.main()
end
