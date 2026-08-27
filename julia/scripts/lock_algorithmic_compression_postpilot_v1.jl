module LockAlgorithmicCompressionPostpilotV1

using Dates
using SHA: sha256
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "lock_algorithmic_compression_design_v1.jl"))
using .LockAlgorithmicCompressionDesignV1: verify_design_lock

include(joinpath(@__DIR__, "finalize_algorithmic_compression_pilot_v1.jl"))
using .FinalizeAlgorithmicCompressionPilotV1: check_postpilot_documents

export freeze_postpilot, main, mutation_test, verify_postpilot_lock

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const STUDY_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "algorithmic_compression_v1",
)
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "algorithmic_compression_v1.toml",
)
const LOCK_PATH = joinpath(STUDY_ROOT, "DESIGN_LOCK_AMENDMENT_001.json")
const INITIAL_LOCK_PATH = joinpath(STUDY_ROOT, "DESIGN_LOCK.json")
const PILOT_ROOT = joinpath(STUDY_ROOT, "pilot")
const PILOT_MANIFEST_PATH = joinpath(PILOT_ROOT, "PILOT_MANIFEST.toml")
const ENVIRONMENT_PATH = joinpath(PILOT_ROOT, "environment.toml")
const RUNNER_PATH = joinpath(
    REPOSITORY_ROOT,
    "julia",
    "scripts",
    "run_algorithmic_compression_pilot_v1.jl",
)
const INITIAL_DESIGN_SHA256 =
    "c5340efc257be1282aabf54ce971a79dcb66d54fd36e0a0cb2e9bac6e2725166"
const ALGORITHM_IDS = (
    "complete_enumeration",
    "requirement_mask_dp",
    "jump_highs_tagged_cover",
    "weighted_greedy",
    "cardinality_greedy",
    "weighted_greedy_reverse_delete",
    "heaviest_safe_first",
    "lightest_safe_first",
    "maximum_immediate_burden_release",
    "minimum_unique_carrier_exposure",
    "declared_source_order",
    "random_order_rechecked_deletion",
    "multistart_random_rechecked_deletion_32",
)


_require(condition::Bool, message::AbstractString) =
    condition ? true : error(message)

_relative(path::AbstractString) = relpath(path, REPOSITORY_ROOT)


function _sha256_file(path::AbstractString)
    return open(path, "r") do io
        bytes2hex(sha256(io))
    end
end


_sha256_bytes(bytes) = bytes2hex(sha256(bytes))


function _json_escape(text::AbstractString)
    return replace(
        String(text),
        '\\' => "\\\\",
        '"' => "\\\"",
        '\n' => "\\n",
        '\r' => "\\r",
        '\t' => "\\t",
    )
end


function _json_array(values)
    return "[" * join(("\"$(_json_escape(string(value)))\"" for value in values), ", ") * "]"
end


function _locked_paths()
    source_paths = sort!(filter(
        path -> endswith(path, ".jl"),
        readdir(joinpath(REPOSITORY_ROOT, "julia", "src"); join = true),
    ))
    fixed = String[
        INITIAL_LOCK_PATH,
        joinpath(STUDY_ROOT, "PILOT_REPORT.md"),
        joinpath(STUDY_ROOT, "amendments", "AMENDMENT_001.md"),
        joinpath(PILOT_ROOT, "PILOT_MANIFEST.toml"),
        joinpath(PILOT_ROOT, "environment.toml"),
        joinpath(PILOT_ROOT, "pilot_runs.csv"),
        joinpath(PILOT_ROOT, "pilot_failures.csv"),
        joinpath(REPOSITORY_ROOT, "julia", "Project.toml"),
        joinpath(REPOSITORY_ROOT, "julia", "Manifest.toml"),
        RUNNER_PATH,
        joinpath(
            REPOSITORY_ROOT,
            "julia",
            "scripts",
            "finalize_algorithmic_compression_pilot_v1.jl",
        ),
        @__FILE__,
    ]
    return sort!(unique(vcat(fixed, source_paths)))
end


function _locked_hashes()
    paths = _locked_paths()
    all(isfile, paths) || error("a post-pilot locked input is absent")
    return Dict(_relative(path) => _sha256_file(path) for path in paths)
end


function _aggregate_hash(hashes)
    io = IOBuffer()
    for path in sort!(collect(keys(hashes)))
        write(io, path, '\0', hashes[path], '\n')
    end
    return _sha256_bytes(take!(io))
end


function _pilot_manifest_complete()
    manifest = TOML.parsefile(PILOT_MANIFEST_PATH)
    listed = sort!(String[String(row["path"]) for row in manifest["files"]])
    actual = sort!(String[
        _relative(joinpath(directory, name)) for
        (directory, _, names) in walkdir(PILOT_ROOT) for name in names if
        joinpath(directory, name) != PILOT_MANIFEST_PATH
    ])
    listed == actual || error("pilot manifest does not enumerate the exact pilot artifact set")
    for row in manifest["files"]
        path = joinpath(REPOSITORY_ROOT, String(row["path"]))
        _sha256_file(path) == row["sha256"] || error(
            "pilot manifest hash mismatch for $(row["path"])",
        )
    end
    return length(listed)
end


function _final_seed_count()
    registries = load_algorithmic_benchmark_registries()
    final_values = Set{Int}()
    final_rows = 0
    for (spec, seed) in zip(registries.instances, registries.seeds)
        spec.phase == :final || continue
        final_rows += 1
        union!(
            final_values,
            (
                seed.execution_order_key,
                seed.generator_seed,
                seed.random_order_seed,
                seed.multistart_seed,
                seed.mip_seed,
            ),
        )
    end
    _require(final_rows == 173, "final registry row count changed")
    _require(length(final_values) == 865, "final seed value count changed")
    return length(final_values)
end


function _final_outputs_absent(config)
    for relative in config["design_lock"]["required_absent_outputs"]
        startswith(String(relative), "experiments/algorithmic_compression_v1/pilot/") &&
            continue
        path = joinpath(REPOSITORY_ROOT, String(relative))
        !ispath(path) || error("final output exists before post-pilot lock: $relative")
    end
    return true
end


function _source_matches_pilot_commit(environment)
    commit = String(environment["git_commit"])
    command = `git -C $REPOSITORY_ROOT diff --quiet $commit -- julia/src julia/Project.toml julia/Manifest.toml`
    success(command) || error(
        "tracked algorithm source differs from the pilot's recorded commit",
    )
    _sha256_file(RUNNER_PATH) == environment["runner_sha256"] || error(
        "pilot runner differs from its recorded pilot hash",
    )
    return true
end


function _prelock_validation()
    verify_design_lock(CONFIG_PATH) == INITIAL_DESIGN_SHA256 || error(
        "initial design aggregate changed",
    )
    check_postpilot_documents()
    config = TOML.parsefile(CONFIG_PATH)
    _final_outputs_absent(config)
    environment = TOML.parsefile(ENVIRONMENT_PATH)
    environment["final_seed_used"] === false || error("final seed entered pilot")
    _source_matches_pilot_commit(environment)
    manifested_files = _pilot_manifest_complete()
    final_seed_values = _final_seed_count()
    return (; config, environment, manifested_files, final_seed_values)
end


function _lock_text(locked_at, validation, hashes)
    config = validation.config
    algorithms = _json_array(ALGORITHM_IDS)
    outcomes = _json_array(config["analysis"]["primary_estimands"])
    preprocessing = _json_array(vcat(
        config["preprocessing"]["paired_mip_variants"],
        config["preprocessing"]["paired_dp_variants_family_a"],
        [config["preprocessing"]["secondary_heuristic_variant"]],
    ))
    file_rows = join(
        (
            "    \"$(_json_escape(path))\": \"$(hashes[path])\"" for
            path in sort!(collect(keys(hashes)))
        ),
        ",\n",
    )
    return """{
  "schema_version": "registered-algorithmic-compression-benchmark-postpilot-lock-v1",
  "experiment_id": "registered-algorithmic-compression-benchmark-v1",
  "amendment_number": 1,
  "locked_at_utc": "$locked_at",
  "lock_stage": "post-pilot, pre-final-outcome freeze",
  "prior_lock_path": "experiments/algorithmic_compression_v1/DESIGN_LOCK.json",
  "prior_design_sha256": "$INITIAL_DESIGN_SHA256",
  "pilot_outcomes_read_before_lock": true,
  "final_outcomes_read_before_lock": false,
  "final_outcome_files_absent_at_lock": true,
  "pilot_results_excluded_from_final_analysis": true,
  "final_execution_status": "BLOCKED_PENDING_REGISTERED_RUNNER_GATES",
  "pilot_manifested_file_count": $(validation.manifested_files),
  "final_instance_count": 173,
  "final_seed_value_count": $(validation.final_seed_values),
  "final_grid": {
    "family_a_strategy_counts": [7, 11, 15],
    "family_a_requirement_counts": [6, 10],
    "family_a_instances": 24,
    "family_b_strategy_counts": [64, 192],
    "family_b_requirement_counts": [32, 64],
    "family_b_instances": 128,
    "family_c_mechanisms": 7,
    "family_c_scales": ["small", "medium", "large"],
    "family_c_instances": 21
  },
  "algorithms": $algorithms,
  "preprocessing_variants": $preprocessing,
  "time_limits_seconds": {
    "small_exact_or_mip": 300,
    "small_deterministic": 60,
    "small_randomized": 120,
    "medium_mip": 900,
    "medium_deterministic": 300,
    "medium_randomized": 600,
    "large_mip": 1800,
    "large_deterministic": 600,
    "large_randomized": 900,
    "adversarial_enumeration": 300,
    "adversarial_dp": 300
  },
  "memory_limit_gib_per_process": 16,
  "primary_outcomes": $outcomes,
  "analysis_plan_sha256": "$(_sha256_file(joinpath(STUDY_ROOT, "ANALYSIS_PLAN.md")))",
  "seed_registry_sha256": "$(_sha256_file(joinpath(STUDY_ROOT, "registry", "SEED_REGISTRY.csv")))",
  "pilot_manifest_sha256": "$(_sha256_file(PILOT_MANIFEST_PATH))",
  "locked_files_aggregate_sha256": "$(_aggregate_hash(hashes))",
  "locked_file_count": $(length(hashes)),
  "mutation_test_contract": "simulated one-file byte mutation must be rejected for every locked file",
  "files": {
$file_rows
  }
}
"""
end


function freeze_postpilot()
    !isfile(LOCK_PATH) || error("post-pilot lock exists; verify instead of overwriting")
    validation = _prelock_validation()
    hashes = _locked_hashes()
    locked_at = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SSZ")
    text = _lock_text(locked_at, validation, hashes)
    open(LOCK_PATH, "w") do io
        write(io, text)
    end
    println(
        "post-pilot lock written: aggregate=$(_aggregate_hash(hashes)), " *
        "locked_files=$(length(hashes)), final_outputs_read=false",
    )
    return _aggregate_hash(hashes)
end


function _lock_contains_hash_map(lock_text, hashes)
    for (path, hash) in hashes
        fragment = "\"$(_json_escape(path))\": \"$hash\""
        occursin(fragment, lock_text) || return false
    end
    return true
end


function verify_postpilot_lock()
    isfile(LOCK_PATH) || error("post-pilot lock is absent")
    validation = _prelock_validation()
    hashes = _locked_hashes()
    text = read(LOCK_PATH, String)
    fragments = (
        "\"prior_design_sha256\": \"$INITIAL_DESIGN_SHA256\"",
        "\"pilot_outcomes_read_before_lock\": true",
        "\"final_outcomes_read_before_lock\": false",
        "\"final_outcome_files_absent_at_lock\": true",
        "\"final_execution_status\": \"BLOCKED_PENDING_REGISTERED_RUNNER_GATES\"",
        "\"final_instance_count\": 173",
        "\"final_seed_value_count\": $(validation.final_seed_values)",
        "\"locked_files_aggregate_sha256\": \"$(_aggregate_hash(hashes))\"",
        "\"locked_file_count\": $(length(hashes))",
    )
    for fragment in fragments
        occursin(fragment, text) || error("post-pilot lock is missing or stale: $fragment")
    end
    _lock_contains_hash_map(text, hashes) || error("post-pilot locked-file hash mismatch")
    println(
        "post-pilot lock current: aggregate=$(_aggregate_hash(hashes)); " *
        "final_N=173; final_outputs_read=false",
    )
    return _aggregate_hash(hashes)
end


function mutation_test()
    verify_postpilot_lock()
    lock_text = read(LOCK_PATH, String)
    hashes = _locked_hashes()
    rejected = 0
    for path in sort!(collect(keys(hashes)))
        absolute = joinpath(REPOSITORY_ROOT, path)
        mutated = copy(hashes)
        bytes = read(absolute)
        push!(bytes, UInt8('\n'))
        append!(bytes, codeunits("POSTPILOT_LOCK_MUTATION_TEST"))
        mutated[path] = _sha256_bytes(bytes)
        !_lock_contains_hash_map(lock_text, mutated) || error(
            "simulated mutation was not rejected for $path",
        )
        rejected += 1
    end
    rejected == length(hashes) || error("mutation-test count mismatch")
    println(
        "post-pilot mutation test passed: simulated changes rejected for " *
        "$rejected/$rejected locked files; working files were not modified",
    )
    return true
end


function main(args = ARGS)
    mode = isempty(args) ? "--check" : only(args)
    mode == "--freeze" && return freeze_postpilot()
    mode == "--check" && return verify_postpilot_lock()
    mode == "--mutation-test" && return mutation_test()
    error(
        "usage: lock_algorithmic_compression_postpilot_v1.jl " *
        "[--freeze|--check|--mutation-test]",
    )
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    LockAlgorithmicCompressionPostpilotV1.main()
end
