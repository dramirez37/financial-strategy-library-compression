module RunFinancialStrategyLibraryPanelV4

using Printf: @sprintf
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV4.jl"))
using .FinancialStrategyLibraryPanelV4
include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v4_design.jl"))
using .LockFinancialStrategyLibraryPanelV4Design

export design_from_files,
       run_v4,
       serialize_ledger,
       serialize_summary,
       result_gate_status,
       main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v4",
)
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v4.toml",
)
const CALIBRATION_PATH = joinpath(EXPERIMENT_ROOT, "calibration", "CALIBRATION.toml")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK.toml")
const RESULT_ROOT = joinpath(EXPERIMENT_ROOT, "results")
const LEDGER_PATH = joinpath(RESULT_ROOT, "V4_WORLD_LEDGER.csv")
const SUMMARY_PATH = joinpath(RESULT_ROOT, "V4_SUMMARY.csv")
const MANIFEST_PATH = joinpath(RESULT_ROOT, "RESULT_MANIFEST.toml")

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

_float(value::Real) = @sprintf("%.17g", Float64(value))

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _atomic_write(path, text)
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, path; force = true)
    return path
end

function _seed_lookup(path)
    lines = filter(!isempty, strip.(readlines(path)))
    header = split(first(lines), ',')
    result = Dict{String,Int}()
    for line in Iterators.drop(lines, 1)
        row = Dict(String(key) => String(value) for (key, value) in zip(
            header,
            split(line, ','; keepempty = true),
        ))
        result[row["purpose_id"]] = parse(Int, row["base_seed"])
    end
    return result
end

function design_from_files()
    config = TOML.parsefile(CONFIG_PATH)
    calibration_payload = TOML.parsefile(CALIBRATION_PATH)
    seeds = _seed_lookup(joinpath(EXPERIMENT_ROOT, "registry", "SEED_REGISTRY.csv"))
    simulation = config["simulation"]
    bridge = config["bridge"]
    structure = config["structure"]
    selection = config["selection"]
    design = MechanismDesign(
        calibration_world_count = simulation["calibration_world_count"],
        evaluation_world_count_per_regime = simulation["evaluation_world_count_per_regime"],
        proposal_sessions = simulation["proposal_sessions"],
        annualization_sessions = simulation["annualization_sessions"],
        proposal_burnin_sessions = simulation["proposal_burnin_sessions"],
        discount_factor = bridge["discount_factor"],
        survival_probability = bridge["survival_probability"],
        admission_probability = bridge["admission_probability"],
        delay_periods = bridge["delay_periods"],
        economic_hurdle = bridge["economic_hurdle"],
        null_quantile = selection["null_calibration_quantile"],
        null_seed = seeds["null_threshold_calibration"],
        proposal_seed = seeds["proposal_world_noise"],
        evaluation_seed = seeds["evaluation_project_event"],
        safe_retention_burden = structure["safe_retention_burden"],
        frontier_retention_burden = structure["frontier_retention_burden"],
        safe_operating_frontier = structure["safe_operating_frontier"],
        frontier_operating_frontier = structure["frontier_operating_frontier"],
    )
    calibration = NoiseCalibration(
        calibration_payload["daily_sigma"],
        calibration_payload["ar1_rho"],
        calibration_payload["student_t_df"],
    )
    return (; design, calibration, config, calibration_payload)
end

const LEDGER_HEADER = [
    "regime_id",
    "world_id",
    "true_margin",
    "proposal_noise",
    "proposal_margin_estimate",
    "adoption_threshold",
    "research_cost",
    "gross_descendant_gain",
    "project_success",
    "oracle_adopt",
    "learned_adopt",
    "realized_project_value",
    "oracle_value",
    "learned_value",
    "frontier_value",
    "safe_retention_burden",
    "frontier_retention_burden",
    "safe_operating_frontier",
    "frontier_operating_frontier",
    "safe_bridge_capability",
    "frontier_bridge_capability",
    "cash_feasible",
    "structural_valid",
    "record_hash",
]

function serialize_ledger(results)
    io = IOBuffer()
    println(io, join(LEDGER_HEADER, ','))
    for result in results
        println(io, join((
            result.regime_id,
            result.world_id,
            _float(result.true_margin),
            _float(result.proposal_noise),
            _float(result.proposal_margin_estimate),
            _float(result.adoption_threshold),
            _float(result.research_cost),
            _float(result.gross_descendant_gain),
            lowercase(string(result.project_success)),
            lowercase(string(result.oracle_adopt)),
            lowercase(string(result.learned_adopt)),
            _float(result.realized_project_value),
            _float(result.oracle_value),
            _float(result.learned_value),
            _float(result.frontier_value),
            result.safe_retention_burden,
            result.frontier_retention_burden,
            result.safe_operating_frontier,
            result.frontier_operating_frontier,
            lowercase(string(result.safe_bridge_capability)),
            lowercase(string(result.frontier_bridge_capability)),
            lowercase(string(result.cash_feasible)),
            lowercase(string(result.structural_valid)),
            result.record_hash,
        ), ','))
    end
    return String(take!(io))
end

const SUMMARY_HEADER = [
    "regime_id",
    "role",
    "world_count",
    "true_margin",
    "theoretical_oracle_value",
    "oracle_mean",
    "oracle_median",
    "oracle_standard_error",
    "oracle_ci_lower",
    "oracle_ci_upper",
    "learned_mean",
    "learned_median",
    "learned_standard_error",
    "learned_ci_lower",
    "learned_ci_upper",
    "adoption_rate",
    "adoption_wilson_lower",
    "adoption_wilson_upper",
    "project_success_rate",
    "structural_pass_rate",
]

function _summary_values(summary)
    return (
        summary.regime_id,
        summary.role,
        summary.world_count,
        _float(summary.true_margin),
        _float(summary.theoretical_oracle_value),
        _float(summary.oracle_mean),
        _float(summary.oracle_median),
        _float(summary.oracle_standard_error),
        _float(summary.oracle_ci_lower),
        _float(summary.oracle_ci_upper),
        _float(summary.learned_mean),
        _float(summary.learned_median),
        _float(summary.learned_standard_error),
        _float(summary.learned_ci_lower),
        _float(summary.learned_ci_upper),
        _float(summary.adoption_rate),
        _float(summary.adoption_wilson_lower),
        _float(summary.adoption_wilson_upper),
        _float(summary.project_success_rate),
        _float(summary.structural_pass_rate),
    )
end

function serialize_summary(summaries)
    io = IOBuffer()
    println(io, join(SUMMARY_HEADER, ','))
    for summary in summaries
        println(io, join(_summary_values(summary), ','))
    end
    return String(take!(io))
end

function result_gate_status(experiment, config)
    summaries = Dict(summary.regime_id => summary for summary in experiment.summaries)
    primary = summaries["powered_positive"]
    null = summaries["null_margin"]
    adversarial = summaries["adversarial_margin"]
    gates = config["success_gates"]
    statuses = Dict{String,Bool}(
        "primary_oracle_lower_95_ci_strictly_positive" => primary.oracle_ci_lower > 0,
        "primary_theoretical_value_inside_95_ci" =>
            primary.oracle_ci_lower <= primary.theoretical_oracle_value <= primary.oracle_ci_upper,
        "primary_learned_lower_95_ci_strictly_positive" => primary.learned_ci_lower > 0,
        "primary_adoption_rate_minimum" =>
            primary.adoption_rate >= Float64(gates["primary_adoption_rate_minimum"]),
        "null_false_adoption_rate_maximum" =>
            null.adoption_rate <= Float64(gates["null_false_adoption_rate_maximum"]),
        "adversarial_adoption_rate_maximum" =>
            adversarial.adoption_rate <= Float64(gates["adversarial_adoption_rate_maximum"]),
        "null_oracle_value_exactly_zero" => null.oracle_mean == 0.0,
        "adversarial_oracle_value_exactly_zero" => adversarial.oracle_mean == 0.0,
        "structural_checks_pass_in_every_world" =>
            all(summary -> summary.structural_pass_rate == 1.0, experiment.summaries),
    )
    statuses["all_registered_gates_pass"] = all(values(statuses))
    return statuses
end

function _summary_payload(summary)
    return Dict{String,Any}(
        "regime_id" => summary.regime_id,
        "role" => summary.role,
        "world_count" => summary.world_count,
        "true_margin" => summary.true_margin,
        "theoretical_oracle_value" => summary.theoretical_oracle_value,
        "oracle_mean" => summary.oracle_mean,
        "oracle_median" => summary.oracle_median,
        "oracle_standard_error" => summary.oracle_standard_error,
        "oracle_ci_lower" => summary.oracle_ci_lower,
        "oracle_ci_upper" => summary.oracle_ci_upper,
        "learned_mean" => summary.learned_mean,
        "learned_median" => summary.learned_median,
        "learned_standard_error" => summary.learned_standard_error,
        "learned_ci_lower" => summary.learned_ci_lower,
        "learned_ci_upper" => summary.learned_ci_upper,
        "adoption_rate" => summary.adoption_rate,
        "adoption_wilson_lower" => summary.adoption_wilson_lower,
        "adoption_wilson_upper" => summary.adoption_wilson_upper,
        "project_success_rate" => summary.project_success_rate,
        "structural_pass_rate" => summary.structural_pass_rate,
    )
end

function run_v4()
    LockFinancialStrategyLibraryPanelV4Design.check_lock()
    existing = filter(isfile, (LEDGER_PATH, SUMMARY_PATH, MANIFEST_PATH))
    isempty(existing) || error("v4 result artifacts already exist; refusing to overwrite")
    inputs = design_from_files()
    experiment = run_experiment(inputs.design, inputs.calibration)
    ledger_text = serialize_ledger(experiment.results)
    summary_text = serialize_summary(experiment.summaries)
    _atomic_write(LEDGER_PATH, ledger_text)
    _atomic_write(SUMMARY_PATH, summary_text)
    gates = result_gate_status(experiment, inputs.config)
    manifest = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v4-result-v1",
        "experiment_id" => inputs.config["experiment_id"],
        "status" => gates["all_registered_gates_pass"] ?
            "COMPLETE_REGISTERED_GATES_PASS" : "COMPLETE_ONE_OR_MORE_REGISTERED_GATES_FAIL",
        "language" => "Julia",
        "julia_threads" => Threads.nthreads(),
        "design_lock_sha256" => _sha256_file(LOCK_PATH),
        "calibration_sha256" => _sha256_file(CALIBRATION_PATH),
        "world_ledger_sha256" => _sha256_file(LEDGER_PATH),
        "summary_csv_sha256" => _sha256_file(SUMMARY_PATH),
        "calibrated_null_cutoff" => experiment.null_cutoff,
        "adoption_threshold" => experiment.threshold,
        "research_cost" => experiment.research_cost,
        "project_success_probability" => experiment.success_probability,
        "calibration_world_count" => inputs.design.calibration_world_count,
        "evaluation_world_count_per_regime" => inputs.design.evaluation_world_count_per_regime,
        "total_world_rows" => length(experiment.results),
        "common_random_numbers_across_regimes" => true,
        "market_alpha_claim_permitted" => false,
        "claim" => inputs.config["claim_boundary"]["positive_claim"],
        "gate_status" => gates,
        "summaries" => [_summary_payload(summary) for summary in experiment.summaries],
    )
    _atomic_write(MANIFEST_PATH, _toml_text(manifest))
    println("V4_RUN_COMPLETE")
    println("adoption threshold: ", experiment.threshold)
    println("research cost: ", experiment.research_cost)
    for summary in experiment.summaries
        println(
            summary.regime_id,
            " margin=", summary.true_margin,
            " oracle_mean=", summary.oracle_mean,
            " learned_mean=", summary.learned_mean,
            " adoption=", summary.adoption_rate,
        )
    end
    println("all registered gates pass: ", gates["all_registered_gates_pass"])
    return (; experiment, manifest)
end

function main(args = ARGS)
    length(args) == 1 && args[1] == "--run" ||
        error("usage: run_financial_strategy_library_panel_v4.jl --run")
    return run_v4()
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    RunFinancialStrategyLibraryPanelV4.main()
end

