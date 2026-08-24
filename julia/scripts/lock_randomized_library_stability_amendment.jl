module LockRandomizedLibraryStabilityAmendment

using Dates
using SHA: sha256
using TOML

include("lock_randomized_library_design_v2.jl")
using .LockRandomizedLibraryDesignV2

export freeze_amendment,
    main,
    validate_amendment,
    verify_amendment_lock

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "randomized_library_stability_amendment_1.toml",
)
const TAXONOMY_MIGRATION = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "randomized_library_v2",
    "STABILITY_LOCK_TAXONOMY_MIGRATION.toml",
)
const REQUIRED_REQUESTED_PREFIXES = [50, 100, 200, 300, 500, 750, 1000]
const REQUIRED_REPORTED_PREFIXES = [
    50,
    100,
    200,
    300,
    500,
    750,
    1000,
    1024,
]
const REQUIRED_FACTORS = (
    "frontier_density",
    "module_overlap",
    "module_complementarity",
    "project_cost",
    "duration",
    "admission",
    "persistence",
)
const REQUIRED_ESTIMANDS = (
    "frontier_positive_loss_frequency",
    "mean_positive_frontier_loss",
    "innovation_safe_loss_frequency",
    "silent_generative_asset_frequency",
    "substitution_frequency",
    "complementarity_frequency",
    "frontier_only_mean_compression_ratio",
    "innovation_safe_mean_compression_ratio",
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

function _validate_parent(config)
    parent = config["parent"]
    parent_config_path = _repo_path(parent["config_path"])
    parent_lock_path = _repo_path(parent["lock_path"])
    _require(isfile(parent_config_path), "parent v2 config is absent")
    _require(isfile(parent_lock_path), "parent v2 lock is absent")
    _require(
        _sha256_file(parent_lock_path) == parent["lock_file_sha256"],
        "parent v2 lock file hash changed",
    )
    parent_design_hash =
        LockRandomizedLibraryDesignV2.verify_design_lock(
            parent_config_path,
        )
    _require(
        parent_design_hash == parent["design_sha256"],
        "parent aggregate design hash changed",
    )
    parent_config = TOML.parsefile(parent_config_path)
    _require(
        Int(parent_config["trial_count"]) ==
        Int(parent["registered_maximum_n"]),
        "parent maximum N differs from the amendment",
    )
    _require(
        parent["maximum_n_selected_after_outcomes"] === false,
        "maximum N cannot be selected after outcomes",
    )
    _require(
        parent["outcomes_read_before_amendment"] === false,
        "the amendment must precede every v2 outcome",
    )
    return parent_config
end

function _validate_factors(config, parent_config)
    for factor in REQUIRED_FACTORS
        _require(
            haskey(config["factors"], factor),
            "amendment is missing factor $factor",
        )
        _require(
            String.(config["factors"][factor]) ==
            String.(parent_config["levels"][factor]),
            "amendment levels changed parent factor $factor",
        )
    end
    _require(
        sort(collect(keys(config["factors"]))) ==
        sort(collect(REQUIRED_FACTORS)),
        "amendment factor set changed",
    )
    return true
end

function _validate_outputs(config, parent_config)
    outputs = config["outputs"]
    _require(
        outputs["cumulative"] ==
        parent_config["outputs"]["stability_summary"],
        "cumulative stability path differs from the parent reservation",
    )
    _require(
        outputs["figure"] ==
        parent_config["outputs"]["stability_figure"],
        "stability figure path differs from the parent reservation",
    )
    parent_paths =
        Set(String.(collect(values(parent_config["outputs"]))))
    _require(
        !(outputs["factor_stratified"] in parent_paths),
        "factor-stability output collides with a parent output",
    )
    _require(
        length(unique(String.(collect(values(outputs))))) ==
        length(outputs),
        "amendment output paths are not unique",
    )
    return true
end

function validate_amendment(config::AbstractDict)
    _require(
        config["schema_version"] ==
        "randomized-library-v2-stability-amendment-v1",
        "unsupported randomized stability amendment schema",
    )
    _require(
        config["registration_status"] ==
        "pre-outcome_amendment_locked_outcomes_not_run",
        "stability amendment is not in the pre-outcome state",
    )
    _require(
        config["theorem_evidence"] === false,
        "stability diagnostics cannot be theorem evidence",
    )
    _require(
        config["design_lock"]["outcomes_read_before_lock"] === false,
        "stability lock must precede v2 outcomes",
    )
    _require(
        config["design_lock"]["candidate_v2_results_used_to_change_specification"] ===
        false,
        "v2 outcomes cannot change the stability specification",
    )
    parent_config = _validate_parent(config)
    maximum_n = Int(config["parent"]["registered_maximum_n"])
    sequential = config["sequential"]
    requested = Int.(sequential["requested_prefixes"])
    reported = Int.(sequential["reported_prefixes"])
    _require(
        requested == REQUIRED_REQUESTED_PREFIXES,
        "requested sequential prefixes changed",
    )
    _require(
        reported == REQUIRED_REPORTED_PREFIXES,
        "reported sequential prefixes changed",
    )
    _require(
        last(reported) == maximum_n,
        "last stability prefix must equal registered maximum N",
    )
    _require(
        Int(sequential["final_estimate_n"]) == maximum_n,
        "final estimate must use registered maximum N",
    )
    _require(
        occursin("none", lowercase(sequential["stopping_rule"])),
        "stability diagnostics cannot define a stopping rule",
    )
    _require(
        Int.(sequential["original_balance_checkpoints"]) ==
        Int.(parent_config["stability"]["prefixes"]),
        "parent balance checkpoints changed",
    )
    _validate_factors(config, parent_config)
    _require(
        sort(collect(keys(config["estimands"]))) ==
        sort(collect(REQUIRED_ESTIMANDS)),
        "registered stability estimand set changed",
    )
    _require(
        config["intervals"]["frequency_method"] ==
        "Wilson score interval",
        "frequency interval method changed",
    )
    _require(
        config["intervals"]["used_for_stopping_or_sample_selection"] ===
        false,
        "frequency intervals cannot select N",
    )
    _require(
        config["mcse"]["used_for_stopping_or_sample_selection"] ===
        false,
        "mean MCSE cannot select N",
    )
    _require(
        config["mcse"]["exact_sample_variance_output"] === true,
        "exact sample variance must accompany every defined mean MCSE",
    )
    _require(
        Int(config["warnings"]["sparse_event_threshold"]) == 20 &&
        Int(config["warnings"]["sparse_nonevent_threshold"]) == 20,
        "sparse frequency thresholds changed",
    )
    _require(
        Int(
            config["warnings"]["conditional_mean_minimum_positive_count"],
        ) == 40,
        "conditional-mean support threshold changed",
    )
    _require(
        config["warnings"]["warning_changes_final_n"] === false &&
        config["warnings"]["warning_changes_estimate_or_denominator"] ===
        false,
        "warnings cannot change estimates or final N",
    )
    _validate_outputs(config, parent_config)
    return (
        maximum_n,
        requested_prefixes = Tuple(requested),
        reported_prefixes = Tuple(reported),
        factors = length(REQUIRED_FACTORS),
        estimands = length(REQUIRED_ESTIMANDS),
    )
end

function _validate_outcomes_absent(config)
    parent_config = TOML.parsefile(
        _repo_path(config["parent"]["config_path"]),
    )
    paths = Set(String.(collect(values(parent_config["outputs"]))))
    union!(paths, String.(collect(values(config["outputs"]))))
    present = sort(
        collect(path for path in paths if isfile(_repo_path(path))),
    )
    _require(
        isempty(present),
        "v2 outcome artifacts exist before the stability amendment lock: " *
        join(present, ", "),
    )
    return true
end

function _design_hashes(config::AbstractDict)
    paths = String.(config["design_lock"]["files"])
    for path in paths
        _require(
            isfile(_repo_path(path)),
            "stability-lock input is absent: $path",
        )
    end
    hashes =
        Dict(path => _sha256_file(_repo_path(path)) for path in paths)
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

function _count_occurrences(text::AbstractString, needle::AbstractString)
    return length(findall(needle, text))
end

function _verify_taxonomy_migration(lock_path, lock_text, hashes)
    migration = TOML.parsefile(TAXONOMY_MIGRATION)
    _require(
        migration["schema_version"] ==
        "randomized-stability-lock-taxonomy-migration-v1",
        "unsupported stability-lock taxonomy migration schema",
    )
    _require(
        migration["taxonomy_migration_only"] === true,
        "stability-lock migration is not taxonomy-only",
    )
    _require(
        _repo_path(migration["registered_lock_path"]) == lock_path,
        "stability-lock migration points to a different registered lock",
    )
    _require(
        _sha256_file(lock_path) == migration["registered_lock_sha256"],
        "registered stability-amendment lock changed",
    )
    registered_design_hash = migration["registered_design_sha256"]
    _require(
        occursin(
            "\"design_sha256\": \"$registered_design_hash\"",
            lock_text,
        ),
        "registered stability-amendment design hash changed",
    )

    allowed = Set(String.(migration["allowed_changed_files"]))
    expected_allowed = Set((
        "julia/scripts/lock_randomized_library_stability_amendment.jl",
        "julia/test/runtests.jl",
    ))
    _require(
        allowed == expected_allowed,
        "stability-lock taxonomy migration changed its allowed file set",
    )
    registered_files = migration["registered_files"]
    current_files = migration["current_files"]
    for path in hashes.paths
        if path in allowed
            _require(
                haskey(registered_files, path) &&
                haskey(current_files, path),
                "stability-lock migration lacks hashes for $path",
            )
            _require(
                occursin(
                    "\"$(_json_escape(path))\": \"$(registered_files[path])\"",
                    lock_text,
                ),
                "registered stability lock no longer records $path",
            )
            _require(
                hashes.hashes[path] == current_files[path],
                "taxonomy-migrated stability-lock input changed: $path",
            )
        else
            _require(
                occursin(
                    "\"$(_json_escape(path))\": \"$(hashes.hashes[path])\"",
                    lock_text,
                ),
                "stability amendment lock is missing or stale for $path",
            )
        end
    end

    wrapper_path = _repo_path("julia/test/runtests.jl")
    reconstructed = read(wrapper_path, String)
    substitutions = migration["runtests_substitutions"]
    _require(
        length(substitutions) == 6,
        "stability-lock taxonomy migration must contain six substitutions",
    )
    for substitution in substitutions
        current = substitution["current"]
        registered = substitution["registered"]
        _require(
            _count_occurrences(reconstructed, current) == 1,
            "current test wrapper does not contain exactly one: $current",
        )
        _require(
            _count_occurrences(reconstructed, registered) == 0,
            "registered financial test name remains active: $registered",
        )
        reconstructed = replace(reconstructed, current => registered)
    end
    reconstructed_hash = bytes2hex(sha256(reconstructed))
    _require(
        reconstructed_hash == registered_files["julia/test/runtests.jl"],
        "test-wrapper changes exceed the registered taxonomy substitutions",
    )
    return registered_design_hash
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
    prefix_text =
        join(Int.(config["sequential"]["reported_prefixes"]), ", ")
    return """{
  \"schema_version\": \"$(config["design_lock"]["schema_version"])\",
  \"experiment_id\": \"$(config["experiment_id"])\",
  \"amendment_id\": \"$(config["amendment_id"])\",
  \"locked_at_utc\": \"$locked_at_utc\",
  \"lock_stage\": \"$(config["design_lock"]["lock_stage"])\",
  \"parent_design_sha256\": \"$(config["parent"]["design_sha256"])\",
  \"outcomes_read_before_lock\": false,
  \"outcome_files_absent_at_lock\": true,
  \"candidate_v2_results_used_to_change_specification\": false,
  \"maximum_n_selected_after_outcomes\": false,
  \"registered_maximum_n\": $(config["parent"]["registered_maximum_n"]),
  \"reported_prefixes\": [$prefix_text],
  \"design_sha256\": \"$(hashes.aggregate)\",
  \"files\": {
$file_rows
  }
}
"""
end

function freeze_amendment(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    validate_amendment(config)
    _validate_outcomes_absent(config)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(
        !isfile(lock_path),
        "stability amendment lock already exists; verify it instead of overwriting it",
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
        "locked randomized-library stability amendment=$(hashes.aggregate) " *
        "at $locked_at_utc",
    )
    return hashes.aggregate
end

function verify_amendment_lock(
    config_path::AbstractString = DEFAULT_CONFIG,
)
    config = TOML.parsefile(config_path)
    validation = validate_amendment(config)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(
        isfile(lock_path),
        "randomized-library stability amendment lock is absent",
    )
    text = read(lock_path, String)
    hashes = _design_hashes(config)
    design_hash = isfile(TAXONOMY_MIGRATION) ?
                  _verify_taxonomy_migration(lock_path, text, hashes) :
                  hashes.aggregate
    required_fragments = (
        "\"parent_design_sha256\": \"$(config["parent"]["design_sha256"])\"",
        "\"outcomes_read_before_lock\": false",
        "\"outcome_files_absent_at_lock\": true",
        "\"candidate_v2_results_used_to_change_specification\": false",
        "\"maximum_n_selected_after_outcomes\": false",
        "\"registered_maximum_n\": $(validation.maximum_n)",
        "\"reported_prefixes\": [$(join(validation.reported_prefixes, ", "))]",
        "\"design_sha256\": \"$design_hash\"",
    )
    for fragment in required_fragments
        _require(
            occursin(fragment, text),
            "stability amendment lock is missing field: $fragment",
        )
    end
    if !isfile(TAXONOMY_MIGRATION)
        for path in hashes.paths
            fragment =
                "\"$(_json_escape(path))\": \"$(hashes.hashes[path])\""
            _require(
                occursin(fragment, text),
                "stability amendment lock is missing or stale for $path",
            )
        end
    end
    println(
        "randomized-library stability amendment current: " *
        "$design_hash; final_N=$(validation.maximum_n), " *
        "prefixes=$(join(validation.reported_prefixes, "/"))",
    )
    return design_hash
end

function main(args = ARGS)
    positional = [
        argument for argument in args if
        !startswith(argument, "--")
    ]
    length(positional) <= 1 || error(
        "usage: lock_randomized_library_stability_amendment.jl " *
        "[config] [--freeze|--check]",
    )
    config_path = isempty(positional) ? DEFAULT_CONFIG : only(positional)
    modes = filter(
        argument -> argument in ("--freeze", "--check"),
        args,
    )
    length(modes) <= 1 || error("choose one stability lock mode")
    mode = isempty(modes) ? "--check" : only(modes)
    return mode == "--freeze" ?
           freeze_amendment(config_path) :
           verify_amendment_lock(config_path)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockRandomizedLibraryStabilityAmendment.main()
end
