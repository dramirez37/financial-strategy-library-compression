module LockFinancialResourceOptimization

using Dates
using SHA: sha256
using TOML

export freeze_design, main, migrate_taxonomy, validate_design, verify_design_lock

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_resource_optimization.toml",
)
const LOCKED_INPUTS = [
    "experiments/configs/financial_resource_optimization.toml",
    "experiments/configs/financial_terminal_audit.toml",
    "experiments/configs/financial_annual_walkforward_audit.toml",
    "experiments/results/summaries/financial_terminal_audit_status.json",
    "experiments/results/summaries/financial_annual_walkforward_audit_status.json",
    "experiments/financial_annual_walkforward_audit/DESIGN_LOCK.json",
    "experiments/financial_resource_optimization/DESIGN_LOCK_REGISTERED.json",
    "experiments/financial_resource_optimization/DESIGN_LOCK_INITIAL.json",
    "experiments/financial_resource_optimization/DESIGN_LOCK_AMENDMENT_1.json",
    "experiments/financial_resource_optimization/DESIGN_LOCK_AMENDMENT_2.json",
    "experiments/financial_resource_optimization/DESIGN_LOCK_AMENDMENT_3.json",
    "experiments/financial_resource_optimization/DESIGN_LOCK_AMENDMENT_4.json",
    "experiments/financial_resource_optimization/DESIGN_LOCK_AMENDMENT_5.json",
    "experiments/financial_resource_optimization/DESIGN_LOCK_AMENDMENT_6.json",
    "experiments/financial_resource_optimization/DESIGN_LOCK_AMENDMENT_7.json",
    "experiments/financial_resource_optimization/IMPLEMENTATION_AMENDMENTS.md",
    "FINANCIAL_AUDIT_TAXONOMY.md",
    "julia/scripts/run_financial_terminal_audit.jl",
    "julia/scripts/run_financial_annual_walkforward_audit.jl",
    "julia/scripts/run_financial_resource_optimization.jl",
    "julia/scripts/lock_financial_resource_optimization.jl",
    "julia/test/test_financial_resource_optimization.jl",
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
    _require(config["schema_version"] == "financial-audit-resource-optimization-v1", "unsupported financial resource design schema")
    _require(config["registration_status"] == "locked_before_resource_optimization_outcomes", "resource extension was not registered before optimization outcomes")
    _require(config["arithmetic"] == "Rational{BigInt}", "exact arithmetic registration changed")
    _require(config["solver"] == "JuMP + HiGHS", "registered solver changed")
    _require(config["solver_tolerances_are_proof"] === false, "solver tolerances cannot be proof")
    _require(config["locked_parent_outcomes_are_modified"] === false, "parent outcomes may not be modified")
    _require(config["pruning_rules_redefined"] === false, "parent pruning rules may not be redefined")
    _require(length(config["audits"]) == 2, "exactly two locked audits must be analyzed")
    _require(Set(String(row["audit_id"]) for row in config["audits"]) == Set(["locked_terminal_v1", "annual_walk_forward_v2"]), "registered audit IDs changed")

    primary = config["primary_resource"]
    _require(primary["schedule_id"] == "uniform_cardinality", "primary resource schedule changed")
    _require(primary["formula"] == "w_s = 1", "primary uniform weights changed")
    _require(primary["objective"] == "minimum cardinality exact safe compression", "primary objective changed")
    secondary = Dict(String(row["schedule_id"]) => row for row in config["secondary_resources"])
    _require(Set(keys(secondary)) == Set(["nonshared_modules", "validation_computation", "documented_complexity"]), "secondary schedule set changed")
    _require(secondary["nonshared_modules"]["formula"] == "w_s = 1 + number of modules carried by s that have exactly one carrier in the frozen source library", "nonshared-module formula changed")
    _require(secondary["validation_computation"]["formula"] == "w_s = 1 + signal lookback/5 + 20*I(trend_100) + 4*I(vol_target_10) + I(signal_flip)", "validation-computation formula changed")
    _require(secondary["documented_complexity"]["formula"] == "w_s = 1 + I(signal != momentum_20) + I(filter != always) + I(horizon != 5) + I(sizing != unit) + I(exit != horizon) + I(risk != notional_cap_1)", "documented-complexity formula changed")
    _require(config["quality"]["may_define_weights"] === false, "held-out quality cannot define weights")
    _require(config["quality"]["reported_ex_post_only"] === true, "quality must remain ex post")
    _require(all(values(config["gates"])), "every registered gate must remain enabled")

    lock = config["design_lock"]
    _require(lock["resource_optimization_results_read_before_lock"] === false, "pre-optimization attestation changed")
    _require(lock["parent_outcomes_used_to_define_weights"] === false, "parent outcomes cannot define weights")
    _require(lock["locked_parent_outcomes_already_exist"] === true, "parent outcomes must remain disclosed as pre-existing")
    _require(Int(lock["implementation_amendment_count"]) == 8, "implementation amendment count changed")
    _require(lock["resource_milp_solved_before_current_lock"] === false, "a resource MILP may not precede the amended lock")
    _require(lock["taxonomy_migration_only"] === true, "active path migration must be taxonomy-only")
    _require(isfile(_repo_path(lock["registered_lock_path"])), "registered pre-taxonomy resource lock is absent")
    _require(isfile(_repo_path(lock["taxonomy_migration_record"])), "financial taxonomy migration record is absent")
    extension_outputs = Set(String.(collect(values(config["outputs"]))))
    absent_outputs = Set(String.(lock["required_absent_outputs"]))
    _require(extension_outputs == absent_outputs, "required-absent list differs from extension outputs")
    _require(all(path -> occursin("financial_resource_optimization", path) || path == "FINANCIAL_RESOURCE_OPTIMIZATION.md", extension_outputs), "an extension output lacks the descriptive resource taxonomy")

    parent_outputs = Set{String}()
    for audit in config["audits"]
        parent = TOML.parsefile(_repo_path(audit["config"]))
        union!(parent_outputs, String.(collect(values(parent["outputs"]))))
    end
    _require(isempty(intersect(parent_outputs, extension_outputs)), "extension paths overlap locked parent outputs")
    if require_outputs_absent
        present = sort([path for path in absent_outputs if isfile(_repo_path(path))])
        _require(isempty(present), "resource outcome exists before design freeze: $(join(present, ", "))")
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
  \"resource_optimization_results_read_before_lock\": false,
  \"parent_outcomes_used_to_define_weights\": false,
  \"locked_parent_outcomes_already_exist\": true,
  \"implementation_amendment_count\": 8,
  \"resource_milp_solved_before_current_lock\": false,
  \"outputs_absent_at_freeze\": true,
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

function _taxonomy_lock_text(config, design, locked_at)
    file_rows = join((
        "    \"$(_json_escape(path))\": \"$(design.hashes[path])\"" for path in LOCKED_INPUTS
    ), ",\n")
    registered_path = String(config["design_lock"]["registered_lock_path"])
    registered_hash = _sha256_file(_repo_path(registered_path))
    migration_record = String(config["design_lock"]["taxonomy_migration_record"])
    return """{
  \"schema_version\": \"$(config["design_lock"]["schema_version"])\",
  \"experiment_id\": \"$(config["experiment_id"])\",
  \"locked_at_utc\": \"$locked_at\",
  \"lock_stage\": \"taxonomy-only public-path migration after the registered resource solve\",
  \"resource_optimization_results_read_before_original_lock\": false,
  \"parent_outcomes_used_to_define_weights\": false,
  \"locked_parent_outcomes_already_exist\": true,
  \"implementation_amendment_count\": 8,
  \"resource_milp_solved_before_original_lock\": false,
  \"outputs_absent_at_original_freeze\": true,
  \"taxonomy_migration_only\": true,
  \"scientific_fields_unchanged\": true,
  \"registered_design_lock_path\": \"$(_json_escape(registered_path))\",
  \"registered_design_lock_sha256\": \"$registered_hash\",
  \"taxonomy_migration_record\": \"$(_json_escape(migration_record))\",
  \"design_sha256\": \"$(design.aggregate)\",
  \"files\": {
$file_rows
  }
}
"""
end

function freeze_design(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    validate_design(config; require_outputs_absent = true)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(!isfile(lock_path), "financial resource design lock already exists; verify it instead of overwriting it")
    design = _design_hashes()
    locked_at = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SSZ")
    mkpath(dirname(lock_path))
    open(lock_path, "w") do io
        write(io, _lock_text(config, design, locked_at))
    end
    println("locked financial resource design=$(design.aggregate) before optimization outcomes at $locked_at")
    return design.aggregate
end

function migrate_taxonomy(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    validate_design(config)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(!isfile(lock_path), "financial resource design lock already exists; verify it instead of overwriting it")
    outputs = String.(collect(values(config["outputs"])))
    _require(all(path -> isfile(_repo_path(path)), outputs), "taxonomy migration requires the registered outputs to remain present")
    design = _design_hashes()
    locked_at = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SSZ")
    mkpath(dirname(lock_path))
    open(lock_path, "w") do io
        write(io, _taxonomy_lock_text(config, design, locked_at))
    end
    println("bound descriptive financial taxonomy to registered design=$(design.aggregate) at $locked_at")
    return design.aggregate
end

function verify_design_lock(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    validate_design(config)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(isfile(lock_path), "financial resource design lock is absent")
    text = read(lock_path, String)
    design = _design_hashes()
    registered_path = String(config["design_lock"]["registered_lock_path"])
    registered_hash = _sha256_file(_repo_path(registered_path))
    for fragment in (
        "\"resource_optimization_results_read_before_original_lock\": false",
        "\"parent_outcomes_used_to_define_weights\": false",
        "\"locked_parent_outcomes_already_exist\": true",
        "\"implementation_amendment_count\": 8",
        "\"resource_milp_solved_before_original_lock\": false",
        "\"outputs_absent_at_original_freeze\": true",
        "\"taxonomy_migration_only\": true",
        "\"scientific_fields_unchanged\": true",
        "\"registered_design_lock_path\": \"$(_json_escape(registered_path))\"",
        "\"registered_design_lock_sha256\": \"$registered_hash\"",
        "\"design_sha256\": \"$(design.aggregate)\"",
    )
        _require(occursin(fragment, text), "financial resource lock is missing: $fragment")
    end
    for path in LOCKED_INPUTS
        fragment = "\"$(_json_escape(path))\": \"$(design.hashes[path])\""
        _require(occursin(fragment, text), "financial resource lock is stale for $path")
    end
    println("financial resource design lock current: $(design.aggregate)")
    return design.aggregate
end

function main(args = ARGS)
    positional = [argument for argument in args if !startswith(argument, "--")]
    length(positional) <= 1 || error("usage: lock_financial_resource_optimization.jl [config] [--freeze|--migrate-taxonomy|--check]")
    config_path = isempty(positional) ? DEFAULT_CONFIG : only(positional)
    modes = filter(argument -> argument in ("--freeze", "--migrate-taxonomy", "--check"), args)
    length(modes) <= 1 || error("choose exactly one design-lock mode")
    mode = isempty(modes) ? "--check" : only(modes)
    return mode == "--freeze" ? freeze_design(config_path) :
           mode == "--migrate-taxonomy" ? migrate_taxonomy(config_path) :
           verify_design_lock(config_path)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialResourceOptimization.main()
end
