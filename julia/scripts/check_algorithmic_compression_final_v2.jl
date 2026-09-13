module CheckAlgorithmicCompressionFinalV2

include(joinpath(@__DIR__, "audit_algorithmic_compression_final_v2.jl"))
using .AuditAlgorithmicCompressionFinalV2
using SHA: sha256
using TOML

const HISTORICAL_INPUT_SHA256 = Dict{String,String}()


"""Accept added dependencies only; retain every historical dependency and pin."""
function verify_environment_extension(historical_project, current_project,
                                      historical_manifest, current_manifest)
    for (key, value) in historical_project
        if key in ("deps", "compat")
            all(get(current_project[key], name, nothing) == uuid
                for (name, uuid) in value) || error("historical project dependency changed")
        else
            get(current_project, key, nothing) == value || error("historical project field changed: $key")
        end
    end
    for key in ("julia_version", "manifest_format")
        current_manifest[key] == historical_manifest[key] || error("historical manifest format/runtime changed")
    end
    for (name, entries) in historical_manifest["deps"]
        current = get(current_manifest["deps"], name, nothing)
        if name == "StrategyInnovation"
            isnothing(current) && error("local project missing from manifest")
            length(current) == length(entries) == 1 || error("ambiguous local project entry")
            for (key, value) in only(entries)
                if key == "deps"
                    issubset(Set(value), Set(only(current)[key])) || error("local project dependency removed")
                else
                    get(only(current), key, nothing) == value || error("local project identity changed")
                end
            end
        else
            current == entries || error("historical dependency pin changed: $name")
        end
    end
    return nothing
end


function install_historical_makefile_hash!()
    runner = AuditAlgorithmicCompressionFinalV2.AlgorithmicCompressionFinalV2
    lock_module = runner.LockAlgorithmicCompressionDesignV2
    environment = TOML.parsefile(runner._active_environment_path())
    execution_commit = get(environment, "git_commit", "")
    occursin(r"^[0-9a-f]{40}$", execution_commit) || error(
        "recorded benchmark execution commit is malformed",
    )
    lock_text = read(lock_module.AMENDMENT_003_LOCK_PATH, String)
    historical = Dict{String,String}()
    for relative in ("Makefile", "julia/Project.toml", "julia/Manifest.toml")
        historical[relative] = read(
            `git -C $(lock_module.REPOSITORY_ROOT) show $execution_commit:$relative`, String)
        digest = bytes2hex(sha256(codeunits(historical[relative])))
        occursin("\"$relative\": \"$digest\"", lock_text) || error(
            "recorded execution input does not match the lock: $relative")
        HISTORICAL_INPUT_SHA256[normpath(joinpath(lock_module.REPOSITORY_ROOT, relative))] = digest
    end
    verify_environment_extension(
        TOML.parse(historical["julia/Project.toml"]),
        TOML.parsefile(joinpath(lock_module.REPOSITORY_ROOT, "julia/Project.toml")),
        TOML.parse(historical["julia/Manifest.toml"]),
        TOML.parsefile(joinpath(lock_module.REPOSITORY_ROOT, "julia/Manifest.toml")))

    @eval AuditAlgorithmicCompressionFinalV2.AlgorithmicCompressionFinalV2.LockAlgorithmicCompressionDesignV2 begin
        function _sha256_file(path)
            historical = Main.CheckAlgorithmicCompressionFinalV2.HISTORICAL_INPUT_SHA256
            if haskey(historical, normpath(path))
                return historical[normpath(path)]
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
