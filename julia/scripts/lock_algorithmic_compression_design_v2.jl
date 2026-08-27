module LockAlgorithmicCompressionDesignV2

using Dates
using SHA: sha256
using StrategyInnovation
using TOML

export create_design_lock_amendment_v2, create_design_lock_v2, main, verify_design_lock_v2

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "algorithmic_compression_v2.toml",
)
const STUDY_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "algorithmic_compression_v2",
)
const LOCK_PATH = joinpath(STUDY_ROOT, "DESIGN_LOCK.json")
const AMENDMENT_ROOT = joinpath(STUDY_ROOT, "amendments")
const AMENDMENT_LOCK_PATH = joinpath(AMENDMENT_ROOT, "DESIGN_LOCK_AMENDMENT_001.json")
const EXECUTION_FAILURE_PATH = joinpath(AMENDMENT_ROOT, "EXECUTION_FAILURE_001.toml")
const INSTANCE_PATH = joinpath(STUDY_ROOT, "registry", "INSTANCE_REGISTRY.csv")
const SEED_PATH = joinpath(STUDY_ROOT, "registry", "SEED_REGISTRY.csv")
const V1_REGISTRY_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "algorithmic_compression_v1",
    "registry",
)
const REQUIRED_FILES = (
    "experiments/algorithmic_compression_v1/INCOMPLETE_EXECUTION_NOTICE.md",
    "experiments/algorithmic_compression_v2/DESIGN.md",
    "experiments/algorithmic_compression_v2/ANALYSIS_PLAN.md",
    "experiments/algorithmic_compression_v2/REPORTING_RULES.md",
    "experiments/algorithmic_compression_v2/DESIGN_SUMMARY.md",
    "experiments/algorithmic_compression_v2/registry/INSTANCE_REGISTRY.csv",
    "experiments/algorithmic_compression_v2/registry/SEED_REGISTRY.csv",
    "experiments/configs/algorithmic_compression_v2.toml",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/scripts/create_algorithmic_compression_v2_registries.jl",
    "julia/scripts/audit_algorithmic_compression_final_v2.jl",
    "julia/scripts/lock_algorithmic_compression_design_v2.jl",
    "julia/scripts/run_algorithmic_compression_final_v2.jl",
    "julia/scripts/run_algorithmic_compression_final_worker_v1.jl",
    "julia/test/run_algorithmic_compression_v2_tests.jl",
    "julia/test/test_algorithmic_compression_v2.jl",
    "Makefile",
)
const AMENDMENT_FILES = (
    "experiments/algorithmic_compression_v2/DESIGN_LOCK.json",
    "experiments/algorithmic_compression_v2/amendments/AMENDMENT_001.md",
    "experiments/algorithmic_compression_v2/amendments/EXECUTION_FAILURE_001.toml",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _all_seed_values(registries)
    values = UInt64[]
    for seed in registries.seeds
        append!(values, UInt64[
            seed.execution_order_key,
            seed.generator_seed,
            seed.random_order_seed,
            seed.multistart_seed,
            seed.mip_seed,
        ])
    end
    return values
end

function _validate(config_path)
    config = TOML.parsefile(config_path)
    config["schema_version"] == "registered-algorithmic-compression-benchmark-v2" ||
        error("unexpected v2 config schema")
    execution = config["execution"]
    execution["process_concurrency_for_timing"] == 8 || error("v2 requires eight lanes")
    execution["supervisor_julia_threads"] == 8 || error("v2 requires eight supervisor threads")
    execution["worker_julia_threads"] == 1 || error("v2 workers must be one-threaded")
    execution["blas_threads"] == 1 || error("v2 BLAS must be one-threaded")
    execution["per_worker_memory_mib"] == 1536 || error("v2 worker memory limit changed")
    solver = config["solver"]["highs"]
    solver["threads"] == 1 || error("HiGHS thread count changed")
    solver["parallel"] == "off" || error("HiGHS parallel mode changed")

    registries = load_algorithmic_benchmark_registries(INSTANCE_PATH, SEED_PATH)
    counts = Dict(phase => count(spec -> spec.phase == phase, registries.instances) for
                  phase in (:dry_run, :pilot, :final))
    counts == Dict(:dry_run => 3, :pilot => 11, :final => 173) ||
        error("v2 registry phase counts changed: $counts")
    all(startswith(spec.instance_id, "V2-") for spec in registries.instances) ||
        error("v2 instance identifier without V2 prefix")
    all(startswith(seed.seed_id, "SEED-V2-") for seed in registries.seeds) ||
        error("v2 seed identifier without V2 prefix")
    values = _all_seed_values(registries)
    length(values) == length(unique(values)) || error("v2 seed values are not globally unique")
    v1 = load_algorithmic_benchmark_registries(
        joinpath(V1_REGISTRY_ROOT, "INSTANCE_REGISTRY.csv"),
        joinpath(V1_REGISTRY_ROOT, "SEED_REGISTRY.csv"),
    )
    isempty(intersect(Set(values), Set(_all_seed_values(v1)))) || error("v1/v2 seed overlap")
    unit_count = sum(begin
        base = 22
        base += spec.exact_enumeration_required ? 1 : 0
        base += spec.exact_dp_required ? 1 : 0
        base += spec.exact_dp_required && spec.family == :small_exact ? 1 : 0
        base
    end for spec in registries.instances if spec.phase == :final)
    unit_count == 3907 || error("registered run-unit count changed: $unit_count")
    for path in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, path)) || error("missing lock input: $path")
    end
    return (; config, registries, counts, unit_count)
end

function _hashes()
    return Dict(path => _sha256_file(joinpath(REPOSITORY_ROOT, path)) for path in REQUIRED_FILES)
end

function _amended_hashes()
    paths = (REQUIRED_FILES..., AMENDMENT_FILES...)
    return Dict(path => _sha256_file(joinpath(REPOSITORY_ROOT, path)) for path in paths)
end

function _aggregate(hashes)
    return _sha256_text(join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    ))
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "registered-algorithmic-compression-benchmark-lock-v2",
  "experiment_id": "registered-algorithmic-compression-benchmark-v2",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "final_outcomes_observed_before_lock": false,
  "worker_count": 8,
  "supervisor_julia_threads": 8,
  "worker_julia_threads": 1,
  "worker_blas_threads": 1,
  "worker_highs_threads": 1,
  "final_instance_count": 173,
  "registered_run_unit_count": 3907,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function create_design_lock_v2(config_path::AbstractString = DEFAULT_CONFIG)
    _validate(config_path)
    results = joinpath(STUDY_ROOT, "results")
    isdir(results) && !isempty(readdir(results)) && error(
        "cannot create the prospective lock after v2 results exist",
    )
    text = _render_lock(_hashes())
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, LOCK_PATH; force = true)
    return LOCK_PATH
end

function _verify_hash_manifest(text::AbstractString, hashes)
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) ||
            error("v2 design lock mismatch: $path")
    end
    occursin("\"aggregate_sha256\": \"$(_aggregate(hashes))\"", text) ||
        error("v2 design lock aggregate mismatch")
    return true
end

function _render_amendment_lock(hashes, original_lock_sha256, original_aggregate)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "registered-algorithmic-compression-benchmark-lock-amendment-v2",
  "experiment_id": "registered-algorithmic-compression-benchmark-v2",
  "amendment_id": "AMENDMENT_001",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "prior_design_lock_sha256": "$original_lock_sha256",
  "prior_design_lock_aggregate_sha256": "$original_aggregate",
  "registered_final_seed_consumed_before_amendment": true,
  "generation_record_count_before_amendment": 1,
  "raw_algorithm_record_count_before_amendment": 0,
  "algorithm_outcome_observed_before_amendment": false,
  "scientific_comparison_performed_before_amendment": false,
  "repair_scope": "generation-failure dispatch arity only",
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function create_design_lock_amendment_v2(config_path::AbstractString = DEFAULT_CONFIG)
    _validate(config_path)
    isfile(LOCK_PATH) || error("original v2 design lock is absent")
    isfile(EXECUTION_FAILURE_PATH) || error("amendment execution-failure record is absent")
    failure = TOML.parsefile(EXECUTION_FAILURE_PATH)
    original_hash = _sha256_file(LOCK_PATH)
    original_hash == failure["original_design_lock_sha256"] || error(
        "original design lock no longer matches the failure record",
    )
    raw_root = joinpath(STUDY_ROOT, "results", "raw_runs")
    raw_count = isdir(raw_root) ? sum(length(files) for (_, _, files) in walkdir(raw_root)) : 0
    raw_count == 0 || error("amendment 001 is valid only before any algorithm raw record")
    initial_text = read(LOCK_PATH, String)
    aggregate_match = match(r"\"aggregate_sha256\"\s*:\s*\"([0-9a-f]{64})\"", initial_text)
    isnothing(aggregate_match) && error("original lock aggregate is unavailable")
    text = _render_amendment_lock(
        _amended_hashes(),
        original_hash,
        aggregate_match.captures[1],
    )
    mkpath(AMENDMENT_ROOT)
    temporary = AMENDMENT_LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, AMENDMENT_LOCK_PATH; force = true)
    return AMENDMENT_LOCK_PATH
end

function verify_design_lock_v2(config_path::AbstractString = DEFAULT_CONFIG)
    _validate(config_path)
    isfile(LOCK_PATH) || error("v2 design lock is absent")
    text = isfile(AMENDMENT_LOCK_PATH) ? read(AMENDMENT_LOCK_PATH, String) :
           read(LOCK_PATH, String)
    hashes = isfile(AMENDMENT_LOCK_PATH) ? _amended_hashes() : _hashes()
    _verify_hash_manifest(text, hashes)
    if isfile(AMENDMENT_LOCK_PATH)
        failure = TOML.parsefile(EXECUTION_FAILURE_PATH)
        original_hash = _sha256_file(LOCK_PATH)
        original_hash == failure["original_design_lock_sha256"] || error(
            "original v2 design lock changed after amendment",
        )
        occursin("\"prior_design_lock_sha256\": \"$original_hash\"", text) ||
            error("amendment does not bind the original design lock")
        occursin("\"algorithm_outcome_observed_before_amendment\": false", text) ||
            error("amendment outcome boundary is not locked")
    else
        occursin("\"final_outcomes_observed_before_lock\": false", text) ||
            error("v2 prospective status is not locked")
    end
    return true
end

function main(args = ARGS)
    mode = isempty(args) ? "--check" : only(args)
    mode == "--create" && return create_design_lock_v2()
    mode == "--create-amendment-001" && return create_design_lock_amendment_v2()
    mode == "--check" && return verify_design_lock_v2()
    error("usage: lock_algorithmic_compression_design_v2.jl [--create|--create-amendment-001|--check]")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockAlgorithmicCompressionDesignV2.main()
end
