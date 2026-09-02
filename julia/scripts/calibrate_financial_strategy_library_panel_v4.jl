module CalibrateFinancialStrategyLibraryPanelV4

using Parquet
using SHA: sha256
using Tables
using TOML

export build_calibration, check_calibration, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v4.toml",
)
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v4",
)
const OUTPUT_PATH = joinpath(EXPERIMENT_ROOT, "calibration", "CALIBRATION.toml")

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

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

function _mean(values)
    isempty(values) && throw(ArgumentError("mean requires observations"))
    return sum(values) / length(values)
end

function _sample_standard_deviation(values)
    length(values) >= 2 || return 0.0
    center = _mean(values)
    return sqrt(sum((value - center)^2 for value in values) / (length(values) - 1))
end

function _median(values)
    isempty(values) && throw(ArgumentError("median requires observations"))
    ordered = sort!(Float64.(collect(values)))
    n = length(ordered)
    return isodd(n) ? ordered[(n + 1) ÷ 2] :
        (ordered[n ÷ 2] + ordered[n ÷ 2 + 1]) / 2
end

function _lag1_correlation(values)
    length(values) >= 3 || return 0.0
    left = @view values[1:(end - 1)]
    right = @view values[2:end]
    left_center = _mean(left)
    right_center = _mean(right)
    numerator = sum((left[index] - left_center) * (right[index] - right_center)
                    for index in eachindex(left))
    left_scale = sum((value - left_center)^2 for value in left)
    right_scale = sum((value - right_center)^2 for value in right)
    denominator = sqrt(left_scale * right_scale)
    return iszero(denominator) ? 0.0 : numerator / denominator
end

function _source_paths(config)
    source_root = joinpath(REPOSITORY_ROOT, config["calibration"]["source_directory"])
    isdir(source_root) || error("v4 calibration source directory is unavailable")
    paths = sort!(filter(
        path -> endswith(path, "-paths.parquet"),
        readdir(source_root; join = true),
    ))
    length(paths) == 37 || error("expected all 37 gate-passed v3 proposal path files")
    return paths
end

function _calibration_statistics(paths)
    strategy_sigmas = Float64[]
    strategy_rhos = Float64[]
    standardized_second_sum = 0.0
    standardized_fourth_sum = 0.0
    standardized_count = 0
    complete_strategy_count = 0
    available_observation_count = 0

    for path in paths
        columns = Tables.columntable(Parquet.Table(path; use_threads = false))
        Set(keys(columns)) == Set((:strategy_id, :date, :net_return, :available)) ||
            error("unexpected proposal-path schema in $(basename(path))")
        n = length(columns.strategy_id)
        length(columns.date) == length(columns.net_return) == length(columns.available) == n ||
            error("proposal-path columns lost alignment")

        date_sums = Dict{String,Float64}()
        date_counts = Dict{String,Int}()
        for index in 1:n
            ismissing(columns.available[index]) && continue
            Bool(columns.available[index]) || continue
            ismissing(columns.date[index]) && continue
            ismissing(columns.net_return[index]) && continue
            value = Float64(columns.net_return[index])
            isfinite(value) || continue
            date = String(columns.date[index])
            date_sums[date] = get(date_sums, date, 0.0) + value
            date_counts[date] = get(date_counts, date, 0) + 1
        end
        date_means = Dict(
            date => date_sums[date] / date_counts[date] for date in keys(date_sums)
        )

        strategy_residuals = Dict{String,Vector{Float64}}()
        for index in 1:n
            ismissing(columns.available[index]) && continue
            Bool(columns.available[index]) || continue
            ismissing(columns.strategy_id[index]) && continue
            ismissing(columns.date[index]) && continue
            ismissing(columns.net_return[index]) && continue
            value = Float64(columns.net_return[index])
            isfinite(value) || continue
            date = String(columns.date[index])
            haskey(date_means, date) || continue
            strategy_id = String(columns.strategy_id[index])
            push!(get!(strategy_residuals, strategy_id, Float64[]), value - date_means[date])
            available_observation_count += 1
        end

        for residuals in values(strategy_residuals)
            length(residuals) >= 100 || continue
            sigma = _sample_standard_deviation(residuals)
            sigma > 1e-10 || continue
            rho = _lag1_correlation(residuals)
            isfinite(rho) || continue
            push!(strategy_sigmas, sigma)
            push!(strategy_rhos, rho)
            complete_strategy_count += 1
            for residual in residuals
                standardized = residual / sigma
                standardized_second_sum += standardized^2
                standardized_fourth_sum += standardized^4
                standardized_count += 1
            end
        end
    end

    isempty(strategy_sigmas) && error("no complete residual strategy paths were calibrated")
    daily_sigma = _median(strategy_sigmas)
    ar1_rho_raw = _median(strategy_rhos)
    ar1_rho = clamp(ar1_rho_raw, -0.50, 0.80)
    standardized_variance = standardized_second_sum / standardized_count
    standardized_fourth_moment = standardized_fourth_sum / standardized_count
    excess_kurtosis = standardized_fourth_moment / standardized_variance^2 - 3
    student_t_df = excess_kurtosis <= 0 ? 30 :
        clamp(round(Int, 6 / excess_kurtosis + 4), 5, 30)
    return (;
        daily_sigma,
        ar1_rho,
        ar1_rho_raw,
        excess_kurtosis,
        student_t_df,
        complete_strategy_count,
        available_observation_count,
        standardized_count,
        median_strategy_sigma = daily_sigma,
        minimum_strategy_sigma = minimum(strategy_sigmas),
        maximum_strategy_sigma = maximum(strategy_sigmas),
        median_strategy_ar1 = ar1_rho_raw,
    )
end

function build_calibration()
    config = TOML.parsefile(CONFIG_PATH)
    config["language"] == "Julia" || error("v4 must remain Julia-first")
    config["calibration"]["gate_passed_cells_only"] === true ||
        error("calibration gate rule changed")
    config["calibration"]["use_every_complete_candidate_path"] === true ||
        error("calibration path census is no longer complete")
    paths = _source_paths(config)
    statistics = _calibration_statistics(paths)
    source_hash_rows = [basename(path) * ":" * _sha256_file(path) for path in paths]
    source_aggregate_sha256 = bytes2hex(sha256(join(source_hash_rows, '\n')))
    binding_path = joinpath(REPOSITORY_ROOT, config["calibration"]["source_manifest"])
    isfile(binding_path) || error("v3 proposal result seal is unavailable")
    payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v4-calibration-v1",
        "experiment_id" => config["experiment_id"],
        "language" => "Julia",
        "source_experiment" => config["calibration"]["source_experiment"],
        "source_role" => config["calibration"]["source_role"],
        "source_file_count" => length(paths),
        "source_aggregate_sha256" => source_aggregate_sha256,
        "source_result_seal_sha256" => _sha256_file(binding_path),
        "config_sha256" => _sha256_file(CONFIG_PATH),
        "security_identifiers_included" => false,
        "return_values_included" => false,
        "calibration_scope" => "all complete candidate paths in all 37 gate-passed v3 proposal cells",
        "residualization" => "subtract within-cell cross-strategy date mean",
        "daily_sigma" => statistics.daily_sigma,
        "ar1_rho" => statistics.ar1_rho,
        "ar1_rho_before_registered_clamp" => statistics.ar1_rho_raw,
        "student_t_df" => statistics.student_t_df,
        "standardized_excess_kurtosis" => statistics.excess_kurtosis,
        "complete_strategy_path_count" => statistics.complete_strategy_count,
        "available_residual_observation_count" => statistics.available_observation_count,
        "standardized_residual_observation_count" => statistics.standardized_count,
        "minimum_strategy_daily_sigma" => statistics.minimum_strategy_sigma,
        "median_strategy_daily_sigma" => statistics.median_strategy_sigma,
        "maximum_strategy_daily_sigma" => statistics.maximum_strategy_sigma,
        "median_strategy_ar1" => statistics.median_strategy_ar1,
    )
    _atomic_write(OUTPUT_PATH, _toml_text(payload))
    return payload
end

function check_calibration()
    isfile(OUTPUT_PATH) || error("v4 calibration output is absent")
    existing = TOML.parsefile(OUTPUT_PATH)
    rebuilt = build_calibration()
    existing == rebuilt || error("v4 calibration no longer reproduces exactly")
    return existing
end

function main(args = ARGS)
    mode = isempty(args) ? "--check" : only(args)
    payload = mode == "--write" ? build_calibration() :
        mode == "--check" ? check_calibration() :
        error("usage: calibrate_financial_strategy_library_panel_v4.jl [--write|--check]")
    println("V4_CALIBRATION_OK")
    println("source files: ", payload["source_file_count"])
    println("complete strategy paths: ", payload["complete_strategy_path_count"])
    println("residual observations: ", payload["available_residual_observation_count"])
    println("daily sigma: ", payload["daily_sigma"])
    println("AR(1): ", payload["ar1_rho"])
    println("Student t df: ", payload["student_t_df"])
    return payload
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    CalibrateFinancialStrategyLibraryPanelV4.main()
end
