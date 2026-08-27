module LockFinancialWeightRobustnessV1

using Dates
using SHA: sha256
using TOML

export create_design_lock, create_design_lock_amendment_001, main, verify_design_lock

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_weight_robustness_v1.toml",
)
const LOCK_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_resource_optimization",
    "WEIGHT_ROBUSTNESS_LOCK.json",
)
const AMENDMENT_LOCK_001_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_resource_optimization",
    "WEIGHT_ROBUSTNESS_LOCK_AMENDMENT_001.json",
)
const FAILURE_001_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_resource_optimization",
    "WEIGHT_ROBUSTNESS_EXECUTION_FAILURE_001.toml",
)
const AMENDMENT_001_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_resource_optimization",
    "WEIGHT_ROBUSTNESS_AMENDMENT_001.md",
)
const REQUIRED_FILES = (
    "DATA_ACCESS.md",
    "THEOREM_LEDGER.md",
    "experiments/configs/financial_weight_robustness_v1.toml",
    "experiments/configs/financial_algorithm_comparison_v1.toml",
    "experiments/configs/financial_resource_optimization.toml",
    "experiments/financial_resource_optimization/WEIGHT_ROBUSTNESS_PROTOCOL.md",
    "experiments/financial_algorithm_comparison_v1/DESIGN_LOCK_AMENDMENT_004.json",
    "experiments/financial_resource_optimization/DESIGN_LOCK.json",
    "experiments/results/summaries/financial_algorithm_comparison_v1_status.toml",
    "journal/aor/reports/PREPROCESSING_THEORY.md",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/FinancialAlgorithmComparison.jl",
    "julia/src/EmptyResidualOptimalityCertificate.jl",
    "julia/src/StrategyInnovation.jl",
    "julia/src/TaggedCoverPreprocessing.jl",
    "julia/scripts/lock_financial_weight_robustness_v1.jl",
    "julia/scripts/run_financial_weight_robustness_v1.jl",
    "julia/test/test_financial_weight_robustness.jl",
)
const AMENDMENT_001_FILES = (
    "experiments/financial_resource_optimization/WEIGHT_ROBUSTNESS_LOCK.json",
    "experiments/financial_resource_optimization/WEIGHT_ROBUSTNESS_EXECUTION_FAILURE_001.toml",
    "experiments/financial_resource_optimization/WEIGHT_ROBUSTNESS_AMENDMENT_001.md",
)

_sha256_file(path::AbstractString) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text::AbstractString) = bytes2hex(sha256(codeunits(text)))


function _validate(config_path::AbstractString)
    config = TOML.parsefile(config_path)
    config["schema_version"] == "financial-weight-robustness-design-v1" ||
        error("unexpected financial weight-robustness schema")
    config["prior_schedule_outcomes_exist"] === true || error(
        "the lock must disclose the preexisting schedule outcomes",
    )
    config["prior_schedule_outcomes_acknowledged"] === true || error(
        "the lock does not acknowledge preexisting outcomes",
    )
    config["robustness_specific_outputs_observed_before_lock"] === false ||
        error("robustness outputs were observed before the lock")
    config["identity_closure_required"] === true || error(
        "the robustness analysis must remain identity-closure only",
    )
    config["exact_arithmetic"] == "Rational{BigInt}" || error(
        "the exact arithmetic declaration changed",
    )
    schedules = config["schedules"]
    expected = [
        (
            "equal_active_strategy",
            "uniform_cardinality",
            "w_s = 1",
            1,
            1,
        ),
        (
            "validation_computation",
            "validation_computation",
            "w_s = 1 + signal_lookback/5 + 20*I(entry_filter=trend_100) + 4*I(risk_constraint=vol_target_10) + I(exit_rule=signal_flip)",
            2,
            38,
        ),
        (
            "governance_complexity",
            "documented_complexity",
            "w_s = 1 + I(signal!=momentum_20) + I(filter!=always) + I(horizon!=5) + I(sizing!=unit) + I(exit!=horizon) + I(risk!=notional_cap_1)",
            1,
            7,
        ),
    ]
    length(schedules) == length(expected) || error("the schedule count changed")
    for (schedule, declaration) in zip(schedules, expected)
        values = (
            String(schedule["schedule_id"]),
            String(schedule["source_schedule_id"]),
            String(schedule["formula"]),
            Int(schedule["expected_min"]),
            Int(schedule["expected_max"]),
        )
        values == declaration || error(
            "a registered financial robustness schedule changed: $(declaration[1])",
        )
    end
    analysis = config["analysis"]
    analysis["terminal_annual_units_pooled"] === false || error(
        "terminal and annual units cannot be pooled",
    )
    analysis["heldout_reported_postdecision_only"] === true || error(
        "the held-out timing rule changed",
    )
    for (_, value) in config["information_boundary"]
        value === false || error("a prohibited information-boundary flag is true")
    end
    publication = config["publication"]
    publication["selected_strategy_identifiers_are_aggregate"] === true ||
        error("the aggregate identity-publication declaration changed")
    publication["raw_or_row_level_licensed_data_permitted"] === false ||
        error("raw licensed data cannot be publicly promoted")
    publication["public_promotion_requires_exact_audit"] === true ||
        error("public promotion must require the exact audit")
    publication["public_promotion_is_automatic"] === false ||
        error("public promotion must remain explicit")
    expected_public_paths = Dict(
        "public_summary_path" => "experiments/results/summaries/financial_resource_optimization_weight_robustness_summary.csv",
        "public_selections_path" => "experiments/results/summaries/financial_resource_optimization_weight_robustness_selections.csv",
        "public_overlap_path" => "experiments/results/summaries/financial_resource_optimization_weight_robustness_identity_overlap.csv",
        "public_rank_path" => "experiments/results/summaries/financial_resource_optimization_weight_robustness_rank_stability.csv",
        "public_certificate_path" => "experiments/results/summaries/financial_resource_optimization_weight_robustness_empty_residual_certificates.csv",
        "public_status_path" => "experiments/results/summaries/financial_resource_optimization_weight_robustness_status.toml",
        "public_report_path" => "experiments/financial_resource_optimization/WEIGHT_ROBUSTNESS_RESULTS.md",
    )
    for (key, expected_path) in expected_public_paths
        config[key] == expected_path || error("the locked public path changed: $key")
    end
    for path in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, path)) || error("missing lock input: $path")
    end
    return config
end


function _hashes()
    return Dict(
        path => _sha256_file(joinpath(REPOSITORY_ROOT, path)) for path in REQUIRED_FILES
    )
end


function _amended_001_hashes()
    return Dict(
        path => _sha256_file(joinpath(REPOSITORY_ROOT, path)) for
        path in (REQUIRED_FILES..., AMENDMENT_001_FILES...)
    )
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
  "schema_version": "financial-weight-robustness-design-lock-v1",
  "experiment_id": "financial-retention-weight-robustness-v1",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "prior_financial_schedule_outcomes_exist": true,
  "prior_financial_schedule_outcomes_acknowledged": true,
  "robustness_specific_outputs_observed_before_lock": false,
  "schedule_search_performed": false,
  "scientific_design_changed_after_results": false,
  "heldout_information_allowed_in_weights_or_optimization": false,
  "terminal_annual_units_pooled": false,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end


function create_design_lock(config_path::AbstractString = DEFAULT_CONFIG)
    config = _validate(config_path)
    local_root = joinpath(REPOSITORY_ROOT, config["local_results_root"])
    isdir(local_root) && !isempty(readdir(local_root)) && error(
        "cannot create the robustness lock after local robustness results exist",
    )
    for key in (
        "public_summary_path",
        "public_selections_path",
        "public_overlap_path",
        "public_rank_path",
        "public_certificate_path",
        "public_status_path",
        "public_report_path",
    )
        isfile(joinpath(REPOSITORY_ROOT, config[key])) && error(
            "cannot create the robustness lock after public output exists: $(config[key])",
        )
    end
    text = _render_lock(_hashes())
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, LOCK_PATH; force = true)
    println("created financial weight-robustness design lock")
    return LOCK_PATH
end


function _render_amendment_lock_001(hashes, prior_lock_sha256)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-weight-robustness-design-lock-amendment-v1",
  "experiment_id": "financial-retention-weight-robustness-v1",
  "amendment_id": "AMENDMENT_001",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "prior_design_lock_sha256": "$prior_lock_sha256",
  "licensed_rows_read_in_failed_attempt": false,
  "parent_source_reconstruction_started": false,
  "algorithm_outcome_observed_before_amendment": false,
  "scientific_design_changed": false,
  "repair_scope": "restore parent-locked data-access text and use the existing financial_resource_optimization public-output prefix",
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end


function create_design_lock_amendment_001(
    config_path::AbstractString = DEFAULT_CONFIG,
)
    config = _validate(config_path)
    for path in (LOCK_PATH, FAILURE_001_PATH, AMENDMENT_001_PATH)
        isfile(path) || error("required amendment-001 chain file is absent: $path")
    end
    local_root = joinpath(REPOSITORY_ROOT, config["local_results_root"])
    isdir(local_root) && !isempty(readdir(local_root)) && error(
        "cannot lock amendment 001 after local robustness results exist",
    )
    failure = TOML.parsefile(FAILURE_001_PATH)
    failure["initial_design_lock_sha256"] == _sha256_file(LOCK_PATH) || error(
        "failure 001 does not identify the initial robustness lock",
    )
    for key in (
        "licensed_rows_read_this_attempt",
        "parent_source_reconstruction_started",
        "algorithm_started",
        "comparison_outcome_observed",
        "local_result_artifact_written",
        "raw_licensed_row_printed_or_written",
        "scientific_design_change_required",
    )
        failure[key] === false || error("failure 001 flag is not false: $key")
    end
    for key in (
        "public_summary_path",
        "public_selections_path",
        "public_overlap_path",
        "public_rank_path",
        "public_certificate_path",
        "public_status_path",
        "public_report_path",
    )
        isfile(joinpath(REPOSITORY_ROOT, config[key])) && error(
            "cannot amend the robustness lock after public output exists: $(config[key])",
        )
    end
    hashes = _amended_001_hashes()
    text = _render_amendment_lock_001(hashes, _sha256_file(LOCK_PATH))
    temporary = AMENDMENT_LOCK_001_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, AMENDMENT_LOCK_001_PATH; force = true)
    println("created financial weight-robustness amendment lock 001")
    return AMENDMENT_LOCK_001_PATH
end


function verify_design_lock(config_path::AbstractString = DEFAULT_CONFIG)
    _validate(config_path)
    isfile(LOCK_PATH) || error("financial weight-robustness lock is absent")
    if isfile(AMENDMENT_LOCK_001_PATH)
        text = read(AMENDMENT_LOCK_001_PATH, String)
        hashes = _amended_001_hashes()
        for path in keys(hashes)
            occursin("\"$path\": \"$(hashes[path])\"", text) || error(
                "financial weight-robustness amendment lock mismatch: $path",
            )
        end
        aggregate = _aggregate(hashes)
        occursin("\"aggregate_sha256\": \"$aggregate\"", text) || error(
            "financial weight-robustness amendment aggregate mismatch",
        )
        prior_sha256 = _sha256_file(LOCK_PATH)
        occursin("\"prior_design_lock_sha256\": \"$prior_sha256\"", text) || error(
            "financial weight-robustness amendment has a stale prior lock",
        )
        occursin("\"algorithm_outcome_observed_before_amendment\": false", text) ||
            error("the robustness amendment outcome-access declaration is invalid")
        occursin("\"scientific_design_changed\": false", text) || error(
            "the robustness amendment scientific-design declaration is invalid",
        )
        return aggregate
    end
    text = read(LOCK_PATH, String)
    hashes = _hashes()
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) || error(
            "financial weight-robustness lock mismatch: $path",
        )
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) || error(
        "financial weight-robustness aggregate mismatch",
    )
    occursin("\"robustness_specific_outputs_observed_before_lock\": false", text) ||
        error("the robustness lock has an invalid outcome-access declaration")
    return aggregate
end


function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_weight_robustness_v1.jl --create|--create-amendment-001|--check",
    )
    only(args) == "--create" && return create_design_lock()
    only(args) == "--create-amendment-001" &&
        return create_design_lock_amendment_001()
    only(args) == "--check" && return println(
        "financial weight-robustness design lock valid: $(verify_design_lock())",
    )
    error("unknown lock mode: $(only(args))")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialWeightRobustnessV1.main()
end
