module LockRandomizedLibraryOptimizationExtension

using Dates
using SHA: sha256
using TOML

export freeze_design, main, validate_design, verify_design_lock

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "randomized_library_optimization_extension_v1.toml",
)
const LOCKED_INPUTS = [
    "experiments/configs/randomized_library_optimization_extension_v1.toml",
    "experiments/configs/randomized_library_stress_v2.toml",
    "experiments/randomized_library_v2/TRIAL_REGISTRY.csv",
    "experiments/randomized_library_v2/DESIGN_LOCK.json",
    "experiments/randomized_library_v2/DESIGN_LOCK_AMENDMENT_1.json",
    "experiments/randomized_library_v2/DESIGN_LOCK_AMENDMENT_2.json",
    "julia/scripts/randomized_library_v2_core.jl",
]

_require(condition::Bool, message::AbstractString) =
    condition ? true : error(message)
_repo_path(path::AbstractString) =
    isabspath(path) ? normpath(path) :
    normpath(joinpath(REPOSITORY_ROOT, path))

function _sha256_file(path::AbstractString)
    return open(path, "r") do io
        bytes2hex(sha256(io))
    end
end

_json_escape(value::AbstractString) =
    replace(value, "\\" => "\\\\", "\"" => "\\\"")

function _design_hashes()
    for path in LOCKED_INPUTS
        _require(isfile(_repo_path(path)), "design-lock input is absent: $path")
    end
    hashes = Dict(path => _sha256_file(_repo_path(path)) for path in LOCKED_INPUTS)
    aggregate = bytes2hex(sha256(join(("$path:$(hashes[path])" for path in LOCKED_INPUTS), "\n")))
    return (; hashes, aggregate)
end

function validate_design(config; require_outputs_absent::Bool = false)
    _require(config["schema_version"] == "randomized-library-v2-optimization-extension-v1", "unsupported optimization-extension design schema")
    _require(config["registration_status"] == "locked_before_optimization_extension_outcomes", "extension is not registered pre-outcome")
    _require(config["arithmetic"] == "Rational{BigInt}", "registered exact arithmetic changed")
    _require(config["theorem_evidence"] === false, "optimization extension cannot be theorem evidence")
    _require(Int(config["sample_size"]) == 1024, "registered extension sample size must be 1024")
    _require(config["parent_outcomes_are_inputs"] === false, "parent outcome tables may not be extension inputs")
    _require(config["pooled_with_parent_results"] === false, "parent and extension results may not be pooled")
    _require(config["sublibrary_rule"] == "enumerate all 2^5=32 inactive-containing source sublibraries", "complete-enumeration rule changed")
    weights = config["weights"]
    _require(weights["rule_id"] == "raw-module-count-v1", "outcome-blind weight rule changed")
    _require(weights["inactive_weight"] == "0//1", "inactive weight changed")
    _require(weights["active_base_weight"] == "1//1", "active base weight changed")
    _require(weights["raw_module_surcharge"] == "1//1", "raw-module surcharge changed")
    _require(weights["positive_active_weights"] === true, "active weights must remain positive")
    _require(
        String.(config["capacity"]["registered_source_burden_fractions"]) ==
        ["0//1", "1//4", "1//2", "3//4", "1//1"],
        "registered capacity grid changed",
    )
    _require(
        String.(config["penalty"]["lambda_grid"]) ==
        ["0//1", "1//4", "1//2", "1//1", "2//1", "4//1"],
        "registered lambda grid changed",
    )
    intervals = config["elasticity"]["intervals"]
    _require(
        [(row["lower_lambda"], row["upper_lambda"]) for row in intervals] ==
        [("1//4", "1//2"), ("1//2", "1//1"), ("1//1", "2//1"), ("2//1", "4//1")],
        "registered elasticity points changed",
    )
    _require(length(config["estimands"]["primary"]) == 9, "primary estimand set changed")
    _require(length(config["factor_slices"]["principal_factors"]) == 7, "principal factor-slice set changed")
    for (_, levels) in config["factor_slices"]["levels"]
        _require(length(levels) == 2, "each registered factor must have exactly two levels")
    end
    _require(all(values(config["gates"])), "every registered hard gate must remain enabled")
    lock = config["design_lock"]
    _require(lock["extension_outcomes_read_before_lock"] === false, "pre-outcome attestation changed")
    _require(lock["parent_outcomes_used_to_change_extension_specification"] === false, "parent outcomes cannot change the extension specification")

    parent_config = TOML.parsefile(_repo_path(config["parent_config"]))
    parent_outputs = Set(String.(collect(values(parent_config["outputs"]))))
    extension_outputs = Set(String.(collect(values(config["outputs"]))))
    _require(isempty(intersect(parent_outputs, extension_outputs)), "extension output paths overlap parent v2 outputs")
    _require(all(startswith(path, "experiments/results/summaries/randomized_library_v2_optimization_v1_") ||
                 path == "RANDOMIZED_LIBRARY_OPTIMIZATION_EXTENSION_V1.md" ||
                 startswith(path, "manuscript/figures/randomized_library_v2_optimization_v1_")
                 for path in extension_outputs), "extension output path lacks explicit v1 versioning")
    absent_paths = Set(String.(lock["required_absent_outputs"]))
    _require(absent_paths == extension_outputs, "required-absent list differs from the complete extension output set")
    if require_outputs_absent
        present = sort(collect(path for path in absent_paths if isfile(_repo_path(path))))
        _require(isempty(present), "extension outcome exists before design freeze: $(join(present, ", "))")
    end
    return true
end

function _lock_text(config, design, locked_at)
    file_rows = join((
        "    \"$(_json_escape(path))\": \"$(design.hashes[path])\"" for path in LOCKED_INPUTS
    ), ",\n")
    output_rows = join((
        "    \"$(_json_escape(path))\"" for path in String.(config["design_lock"]["required_absent_outputs"])
    ), ",\n")
    return """{
  \"schema_version\": \"$(config["design_lock"]["schema_version"])\",
  \"experiment_id\": \"$(config["experiment_id"])\",
  \"locked_at_utc\": \"$locked_at\",
  \"lock_stage\": \"$(config["design_lock"]["lock_stage"])\",
  \"extension_outcomes_read_before_lock\": false,
  \"parent_outcomes_used_to_change_extension_specification\": false,
  \"outputs_absent_at_freeze\": true,
  \"parent_outcomes_are_inputs\": false,
  \"pooled_with_parent_results\": false,
  \"trial_count\": $(config["sample_size"]),
  \"sublibraries_per_trial\": 32,
  \"design_sha256\": \"$(design.aggregate)\",
  \"files\": {
$file_rows
  },
  \"outputs_absent_at_freeze_paths\": [
$output_rows
  ]
}
"""
end

function freeze_design(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    validate_design(config; require_outputs_absent = true)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(!isfile(lock_path), "optimization-extension lock already exists; verify it instead of overwriting it")
    design = _design_hashes()
    locked_at = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SSZ")
    mkpath(dirname(lock_path))
    open(lock_path, "w") do io
        write(io, _lock_text(config, design, locked_at))
    end
    println("locked optimization extension design=$(design.aggregate) before outcomes at $locked_at")
    return design.aggregate
end

function verify_design_lock(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    validate_design(config)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(isfile(lock_path), "optimization-extension design lock is absent")
    text = read(lock_path, String)
    design = _design_hashes()
    fragments = (
        "\"extension_outcomes_read_before_lock\": false",
        "\"parent_outcomes_used_to_change_extension_specification\": false",
        "\"outputs_absent_at_freeze\": true",
        "\"parent_outcomes_are_inputs\": false",
        "\"pooled_with_parent_results\": false",
        "\"trial_count\": $(config["sample_size"])",
        "\"sublibraries_per_trial\": 32",
        "\"design_sha256\": \"$(design.aggregate)\"",
    )
    for fragment in fragments
        _require(occursin(fragment, text), "optimization-extension lock is missing required field: $fragment")
    end
    for path in LOCKED_INPUTS
        fragment = "\"$(_json_escape(path))\": \"$(design.hashes[path])\""
        _require(occursin(fragment, text), "optimization-extension lock is stale for $path")
    end
    println("optimization-extension design lock current: $(design.aggregate); N=$(config["sample_size"])")
    return design.aggregate
end

function main(args = ARGS)
    positional = [argument for argument in args if !startswith(argument, "--")]
    length(positional) <= 1 || error("usage: lock_randomized_library_optimization_extension.jl [config] [--freeze|--check]")
    config_path = isempty(positional) ? DEFAULT_CONFIG : only(positional)
    modes = filter(argument -> argument in ("--freeze", "--check"), args)
    length(modes) <= 1 || error("choose exactly one optimization-extension design-lock mode")
    mode = isempty(modes) ? "--check" : only(modes)
    return mode == "--freeze" ? freeze_design(config_path) : verify_design_lock(config_path)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockRandomizedLibraryOptimizationExtension.main()
end
