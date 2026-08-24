module FreezeFinancialAnnualWalkforwardAudit

using SHA: sha256
using TOML

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(REPOSITORY_ROOT, "experiments", "configs", "financial_annual_walkforward_audit.toml")

_require(condition::Bool, message::AbstractString) = condition ? true : error(message)
_repo_path(path::AbstractString) = isabspath(path) ? normpath(path) : normpath(joinpath(REPOSITORY_ROOT, path))

function _sha256_file(path::AbstractString)
    open(path, "r") do io
        return bytes2hex(sha256(io))
    end
end

_json_escape(value::AbstractString) = replace(value, "\\" => "\\\\", "\"" => "\\\"")

function design_hashes(config::AbstractDict)
    paths = String.(config["design_lock"]["files"])
    for path in paths
        _require(isfile(_repo_path(path)), "design file is absent: $path")
    end
    hashes = Dict(path => _sha256_file(_repo_path(path)) for path in paths)
    aggregate = bytes2hex(sha256(join(("$path:$(hashes[path])" for path in paths), "\n")))
    return (; paths, hashes, aggregate)
end

function _lock_text(config::AbstractDict, hashes, locked_at_utc::AbstractString)
    file_rows = join(
        ("    \"$(_json_escape(path))\": \"$(hashes.hashes[path])\"" for path in hashes.paths),
        ",\n",
    )
    return """{
  \"schema_version\": \"$(config["design_lock"]["schema_version"])\",
  \"experiment_id\": \"$(config["experiment_id"])\",
  \"locked_at_utc\": \"$locked_at_utc\",
  \"lock_stage\": \"$(config["design_lock"]["lock_stage"])\",
  \"initial_analytical_design_sha256\": \"$(config["design_lock"]["initial_analytical_design_sha256"])\",
  \"support_information_read_before_lock\": $(config["design_lock"]["support_information_read_before_lock"]),
  \"candidate_results_used_to_change_analytical_specification\": $(config["design_lock"]["candidate_results_used_to_change_analytical_specification"]),
  \"taxonomy_migration_only\": $(config["design_lock"]["taxonomy_migration_only"]),
  \"registered_design_lock_path\": \"$(_json_escape(config["design_lock"]["registered_lock_path"]))\",
  \"registered_design_lock_sha256\": \"$(_sha256_file(_repo_path(config["design_lock"]["registered_lock_path"])))\",
  \"taxonomy_migration_record\": \"$(_json_escape(config["design_lock"]["taxonomy_migration_record"]))\",
  \"design_sha256\": \"$(hashes.aggregate)\",
  \"files\": {
$file_rows
  }
}
"""
end

function verify_design_lock(config::AbstractDict)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(isfile(lock_path), "annual walk-forward design lock is absent")
    text = read(lock_path, String)
    initial_hash = config["design_lock"]["initial_analytical_design_sha256"]
    _require(occursin("\"initial_analytical_design_sha256\": \"$initial_hash\"", text), "initial analytical lock is missing")
    _require(occursin("\"support_information_read_before_lock\": true", text), "completed lock does not disclose prior support information")
    _require(occursin("\"candidate_results_used_to_change_analytical_specification\": false", text), "completed lock does not attest analytical result blindness")
    _require(occursin("\"taxonomy_migration_only\": true", text), "design lock does not identify the taxonomy-only migration")
    registered_path = config["design_lock"]["registered_lock_path"]
    registered_hash = _sha256_file(_repo_path(registered_path))
    _require(occursin("\"registered_design_lock_path\": \"$(_json_escape(registered_path))\"", text), "registered design-lock path is missing")
    _require(occursin("\"registered_design_lock_sha256\": \"$registered_hash\"", text), "registered design-lock hash is missing")
    hashes = design_hashes(config)
    _require(occursin("\"design_sha256\": \"$(hashes.aggregate)\"", text), "design files changed after the annual walk-forward lock")
    for path in hashes.paths
        _require(occursin("\"$(_json_escape(path))\": \"$(hashes.hashes[path])\"", text), "design-file hash is missing from the lock: $path")
    end
    return hashes.aggregate
end

function freeze(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    _require(config["schema_version"] == "financial-illustration-v2", "unsupported financial protocol")
    _require(config["design_lock"]["taxonomy_migration_only"] === true, "active lock refresh must be taxonomy-only")
    _require(isfile(_repo_path(config["design_lock"]["registered_lock_path"])), "registered pre-taxonomy lock is absent")
    _require(config["design_lock"]["support_information_read_before_lock"] === true, "completed lock must disclose prior support information")
    _require(config["design_lock"]["candidate_results_used_to_change_analytical_specification"] === false, "candidate results may not change the analytical specification")
    hashes = design_hashes(config)
    locked_at_utc = readchomp(`date -u +%Y-%m-%dT%H:%M:%SZ`)
    path = _repo_path(config["design_lock"]["path"])
    _require(!isfile(path), "annual walk-forward design lock already exists; verify it instead of overwriting it")
    mkpath(dirname(path))
    open(path, "w") do io
        write(io, _lock_text(config, hashes, locked_at_utc))
    end
    println("locked design=$(hashes.aggregate) at $locked_at_utc")
    return hashes.aggregate
end

function main(args = ARGS)
    positional = [argument for argument in args if !startswith(argument, "--")]
    config_path = isempty(positional) ? DEFAULT_CONFIG : only(positional)
    if "--check" in args
        config = TOML.parsefile(config_path)
        println("design lock current: $(verify_design_lock(config))")
        return
    end
    return freeze(config_path)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    FreezeFinancialAnnualWalkforwardAudit.main()
end
