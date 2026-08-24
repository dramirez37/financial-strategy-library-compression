module LockRandomizedLibraryExecutionAmendment

using Dates
using SHA: sha256
using TOML

include("lock_randomized_library_design_v2.jl")
using .LockRandomizedLibraryDesignV2

include("lock_randomized_library_stability_amendment.jl")
using .LockRandomizedLibraryStabilityAmendment

export freeze_execution_lock, main, validate_execution_amendment,
    verify_execution_lock

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "randomized_library_execution_amendment_2.toml",
)
const REQUIRED_OUTPUTS = Dict(
    "interaction_signs" =>
        "experiments/results/summaries/randomized_library_v2_interaction_signs.csv",
    "witness_manifest" =>
        "experiments/results/summaries/randomized_library_v2_raw_witness_manifest.csv",
)

_require(condition::Bool, message::AbstractString) =
    condition ? true : error(message)
_repo_path(path::AbstractString) =
    isabspath(path) ? normpath(path) :
    normpath(joinpath(REPOSITORY_ROOT, path))

function _sha256_file(path::AbstractString)
    open(path, "r") do io
        return bytes2hex(sha256(io))
    end
end

function validate_execution_amendment(config::AbstractDict)
    _require(
        config["schema_version"] ==
        "randomized-library-v2-execution-amendment-v1",
        "unsupported execution-amendment schema",
    )
    _require(
        config["registration_status"] ==
        "pre-outcome_execution_implementation_locked",
        "execution amendment is not pre-outcome locked",
    )
    _require(
        config["theorem_evidence"] === false,
        "randomized execution cannot be theorem evidence",
    )
    _require(
        config["outcomes_read_before_amendment"] === false &&
        config["candidate_results_used_to_change_implementation"] === false,
        "execution implementation must be outcome-blind",
    )
    parent = config["parent"]
    parent_hash =
        LockRandomizedLibraryDesignV2.verify_design_lock(
            _repo_path(parent["design_config"]),
        )
    _require(
        parent_hash == parent["design_sha256"],
        "parent v2 design hash changed",
    )
    stability_hash =
        LockRandomizedLibraryStabilityAmendment.verify_amendment_lock(
            _repo_path(parent["stability_config"]),
        )
    _require(
        stability_hash == parent["stability_sha256"],
        "parent stability-amendment hash changed",
    )
    _require(
        Int(parent["registered_maximum_n"]) == 1024,
        "registered maximum N changed",
    )
    _require(
        parent["maximum_n_selected_after_outcomes"] === false,
        "maximum N cannot be selected after outcomes",
    )
    implementation = config["implementation"]
    for field in (
        "raw_state_generation_adapter",
        "all_trials_complete_before_writes",
    )
        _require(
            implementation[field] === true,
            "required execution field $field is false",
        )
    end
    for field in (
        "legacy_generation_methods_changed",
        "direct_compressed_states_permitted",
        "hand_assigned_menus_permitted",
        "hand_assigned_transitions_permitted",
        "hand_assigned_values_permitted",
    )
        _require(
            implementation[field] === false,
            "forbidden execution field $field is true",
        )
    end
    _require(
        implementation["arithmetic"] == "Rational{BigInt}",
        "registered exact arithmetic changed",
    )
    gates = config["hard_gates"]
    for field in (
        "all_compressed_states_have_raw_witnesses",
        "four_raw_witnesses_per_rectangle",
        "all_raw_compressed_values_agree",
        "signed_loss_decomposition_exact",
        "theorem_condition_flags_mechanical",
        "theorem_facing_scalars_rational_bigint",
        "failure_aborts_before_artifact_writes",
    )
        _require(gates[field] === true, "required hard gate $field is false")
    end
    _require(
        gates["innovation_safe_frontier_loss"] == "0//1" &&
        Int(gates["innovation_safe_closure_loss"]) == 0 &&
        gates["innovation_safe_operational_loss"] == "0//1" &&
        gates["innovation_safe_generative_loss"] == "0//1" &&
        gates["innovation_safe_total_loss"] == "0//1",
        "innovation-safe exact-zero gate changed",
    )
    _require(
        Dict(
            String(name) => String(path) for
            (name, path) in config["outputs"]
        ) == REQUIRED_OUTPUTS,
        "execution-amendment output paths changed",
    )
    return (
        maximum_n = 1024,
        parent_hash,
        stability_hash,
        output_count = length(REQUIRED_OUTPUTS),
    )
end

function _outcome_paths(config)
    parent = TOML.parsefile(
        _repo_path(config["parent"]["design_config"]),
    )
    paths = Set(String.(collect(values(parent["outputs"]))))
    stability = TOML.parsefile(
        _repo_path(config["parent"]["stability_config"]),
    )
    union!(paths, String.(collect(values(stability["outputs"]))))
    union!(paths, String.(collect(values(config["outputs"]))))
    return sort(collect(paths))
end

function _require_outcomes_absent(config)
    present = [
        path for path in _outcome_paths(config) if
        isfile(_repo_path(path))
    ]
    _require(
        isempty(present),
        "v2 outcome artifact exists before execution lock: " *
        join(present, ", "),
    )
    return true
end

function _design_hashes(config)
    paths = String.(config["design_lock"]["files"])
    for path in paths
        _require(
            isfile(_repo_path(path)),
            "execution-lock input is absent: $path",
        )
    end
    hashes = Dict(
        path => _sha256_file(_repo_path(path)) for path in paths
    )
    aggregate = bytes2hex(
        sha256(
            join(
                ("$path:$(hashes[path])" for path in paths),
                "\n",
            ),
        ),
    )
    return (; paths, hashes, aggregate)
end

_json_escape(value::AbstractString) =
    replace(value, "\\" => "\\\\", "\"" => "\\\"")

function _lock_text(config, hashes, locked_at_utc)
    file_rows = join(
        (
            "    \"$(_json_escape(path))\": \"$(hashes.hashes[path])\"" for
            path in hashes.paths
        ),
        ",\n",
    )
    return """{
  \"schema_version\": \"$(config["design_lock"]["schema_version"])\",
  \"experiment_id\": \"$(config["experiment_id"])\",
  \"amendment_id\": \"$(config["amendment_id"])\",
  \"locked_at_utc\": \"$locked_at_utc\",
  \"lock_stage\": \"$(config["design_lock"]["lock_stage"])\",
  \"parent_design_sha256\": \"$(config["parent"]["design_sha256"])\",
  \"parent_stability_sha256\": \"$(config["parent"]["stability_sha256"])\",
  \"outcomes_read_before_lock\": false,
  \"outcome_files_absent_at_lock\": true,
  \"candidate_results_used_to_change_implementation\": false,
  \"maximum_n_selected_after_outcomes\": false,
  \"registered_maximum_n\": 1024,
  \"design_sha256\": \"$(hashes.aggregate)\",
  \"files\": {
$file_rows
  }
}
"""
end

function freeze_execution_lock(
    config_path::AbstractString = DEFAULT_CONFIG,
)
    config = TOML.parsefile(config_path)
    validate_execution_amendment(config)
    _require_outcomes_absent(config)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(
        !isfile(lock_path),
        "execution amendment lock exists; verify instead of overwriting",
    )
    hashes = _design_hashes(config)
    locked_at_utc = Dates.format(
        Dates.now(Dates.UTC),
        dateformat"yyyy-mm-ddTHH:MM:SSZ",
    )
    open(lock_path, "w") do io
        write(io, _lock_text(config, hashes, locked_at_utc))
    end
    println(
        "locked randomized-library v2 execution amendment=" *
        "$(hashes.aggregate) at $locked_at_utc",
    )
    return hashes.aggregate
end

function verify_execution_lock(
    config_path::AbstractString = DEFAULT_CONFIG,
)
    config = TOML.parsefile(config_path)
    validation = validate_execution_amendment(config)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(isfile(lock_path), "execution amendment lock is absent")
    text = read(lock_path, String)
    hashes = _design_hashes(config)
    fragments = (
        "\"parent_design_sha256\": \"$(validation.parent_hash)\"",
        "\"parent_stability_sha256\": \"$(validation.stability_hash)\"",
        "\"outcomes_read_before_lock\": false",
        "\"outcome_files_absent_at_lock\": true",
        "\"candidate_results_used_to_change_implementation\": false",
        "\"maximum_n_selected_after_outcomes\": false",
        "\"registered_maximum_n\": 1024",
        "\"design_sha256\": \"$(hashes.aggregate)\"",
    )
    for fragment in fragments
        _require(
            occursin(fragment, text),
            "execution lock is missing field: $fragment",
        )
    end
    for path in hashes.paths
        fragment =
            "\"$(_json_escape(path))\": \"$(hashes.hashes[path])\""
        _require(
            occursin(fragment, text),
            "execution lock is missing or stale for $path",
        )
    end
    println(
        "randomized-library v2 execution amendment current: " *
        "$(hashes.aggregate); final_N=$(validation.maximum_n)",
    )
    return hashes.aggregate
end

function main(args = ARGS)
    positional = [
        argument for argument in args if
        !startswith(argument, "--")
    ]
    length(positional) <= 1 ||
        error(
            "usage: lock_randomized_library_execution_amendment.jl " *
            "[config] [--freeze|--check]",
        )
    config_path = isempty(positional) ? DEFAULT_CONFIG : only(positional)
    modes = filter(
        argument -> argument in ("--freeze", "--check"),
        args,
    )
    length(modes) <= 1 || error("choose one execution-lock mode")
    mode = isempty(modes) ? "--check" : only(modes)
    return mode == "--freeze" ?
           freeze_execution_lock(config_path) :
           verify_execution_lock(config_path)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockRandomizedLibraryExecutionAmendment.main()
end
