module LockFinancialAlgorithmComparisonV1

using Dates
using SHA: sha256
using TOML

export create_design_lock,
    create_design_lock_amendment_001,
    create_design_lock_amendment_002,
    create_design_lock_amendment_003,
    create_design_lock_amendment_004,
    main,
    verify_design_lock

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_algorithm_comparison_v1.toml",
)
const STUDY_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_algorithm_comparison_v1",
)
const LOCK_PATH = joinpath(STUDY_ROOT, "DESIGN_LOCK.json")
const AMENDMENT_LOCK_001_PATH =
    joinpath(STUDY_ROOT, "DESIGN_LOCK_AMENDMENT_001.json")
const AMENDMENT_LOCK_002_PATH =
    joinpath(STUDY_ROOT, "DESIGN_LOCK_AMENDMENT_002.json")
const AMENDMENT_LOCK_003_PATH =
    joinpath(STUDY_ROOT, "DESIGN_LOCK_AMENDMENT_003.json")
const AMENDMENT_LOCK_004_PATH =
    joinpath(STUDY_ROOT, "DESIGN_LOCK_AMENDMENT_004.json")
const FAILURE_001_PATH = joinpath(STUDY_ROOT, "EXECUTION_FAILURE_001.toml")
const FAILURE_002_PATH = joinpath(STUDY_ROOT, "EXECUTION_FAILURE_002.toml")
const FAILURE_003_PATH = joinpath(STUDY_ROOT, "EXECUTION_FAILURE_003.toml")
const FAILURE_004_PATH = joinpath(STUDY_ROOT, "EXECUTION_FAILURE_004.toml")
const AMENDMENT_001_PATH = joinpath(STUDY_ROOT, "AMENDMENT_001.md")
const AMENDMENT_002_PATH = joinpath(STUDY_ROOT, "AMENDMENT_002.md")
const AMENDMENT_003_PATH = joinpath(STUDY_ROOT, "AMENDMENT_003.md")
const AMENDMENT_004_PATH = joinpath(STUDY_ROOT, "AMENDMENT_004.md")
const REQUIRED_FILES = (
    "DATA_ACCESS.md",
    "journal/aor/CLAIM_BOUNDARY.md",
    "journal/aor/reports/FINANCIAL_ALGORITHM_PROTOCOL.md",
    "experiments/configs/financial_algorithm_comparison_v1.toml",
    "experiments/configs/financial_resource_optimization.toml",
    "experiments/configs/financial_terminal_audit.toml",
    "experiments/configs/financial_annual_walkforward_audit.toml",
    "experiments/financial_algorithm_comparison_v1/README.md",
    "experiments/financial_resource_optimization/DESIGN_LOCK.json",
    "experiments/results/summaries/financial_terminal_audit_status.json",
    "experiments/financial_annual_walkforward_audit/DESIGN_LOCK.json",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/FinancialAlgorithmComparison.jl",
    "julia/src/JournalCompressionInstance.jl",
    "julia/src/TaggedCoverPreprocessing.jl",
    "julia/src/ExactJournalCompression.jl",
    "julia/src/GreedyJournalCompression.jl",
    "julia/src/CertifiedDeletionJournalCompression.jl",
    "julia/src/JournalCompressionMIP.jl",
    "julia/scripts/lock_financial_algorithm_comparison_v1.jl",
    "julia/scripts/run_financial_algorithm_comparison_v1.jl",
    "julia/test/test_financial_algorithm_comparison.jl",
)
const AMENDMENT_001_FILES = (
    "experiments/financial_algorithm_comparison_v1/DESIGN_LOCK.json",
    "experiments/financial_algorithm_comparison_v1/EXECUTION_FAILURE_001.toml",
    "experiments/financial_algorithm_comparison_v1/AMENDMENT_001.md",
)
const AMENDMENT_002_FILES = (
    "experiments/financial_algorithm_comparison_v1/DESIGN_LOCK_AMENDMENT_001.json",
    "experiments/financial_algorithm_comparison_v1/EXECUTION_FAILURE_002.toml",
    "experiments/financial_algorithm_comparison_v1/AMENDMENT_002.md",
)
const AMENDMENT_003_FILES = (
    "experiments/financial_algorithm_comparison_v1/DESIGN_LOCK_AMENDMENT_002.json",
    "experiments/financial_algorithm_comparison_v1/EXECUTION_FAILURE_003.toml",
    "experiments/financial_algorithm_comparison_v1/AMENDMENT_003.md",
)
const AMENDMENT_004_FILES = (
    "experiments/financial_algorithm_comparison_v1/DESIGN_LOCK_AMENDMENT_003.json",
    "experiments/financial_algorithm_comparison_v1/EXECUTION_FAILURE_004.toml",
    "experiments/financial_algorithm_comparison_v1/AMENDMENT_004.md",
)


_sha256_file(path::AbstractString) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text::AbstractString) = bytes2hex(sha256(codeunits(text)))


function _validate(config_path::AbstractString)
    config = TOML.parsefile(config_path)
    config["schema_version"] == "financial-algorithm-comparison-design-v1" ||
        error("unexpected financial algorithm comparison schema")
    config["identity_closure_required"] === true || error(
        "the financial comparison must remain identity-closure only",
    )
    config["exact_arithmetic"] == "Rational{BigInt}" || error(
        "the exact arithmetic declaration changed",
    )
    config["public_aggregate_promotion_automatic"] === false || error(
        "public aggregate promotion must remain an explicit audited action",
    )
    config["public_summary_path"] ==
        "experiments/results/summaries/financial_algorithm_comparison_v1.csv" ||
        error("the public aggregate path changed")
    config["public_status_path"] ==
        "experiments/results/summaries/financial_algorithm_comparison_v1_status.toml" ||
        error("the public status path changed")
    config["public_report_path"] ==
        "journal/aor/reports/FINANCIAL_ALGORITHM_RESULTS.md" ||
        error("the generated results-report path changed")
    config["parent_source_frontier_must_match_committed_certificate"] === true ||
        error("the exact committed-frontier source gate changed")
    config["parent_source_closure_must_match_committed_certificate"] === true ||
        error("the exact committed-closure source gate changed")
    config["annual_parent_replay_status"] ==
        "KNOWN_BLOCKED_BY_ANALYTICAL_VERSUS_TAXONOMY_HASH_IDENTITY" ||
        error("the annual parent replay limitation changed")
    String.(config["registered_weight_schedules"]) == [
        "uniform_cardinality",
        "nonshared_modules",
        "validation_computation",
        "documented_complexity",
    ] || error("the registered weight schedules or their order changed")
    algorithms = config["algorithms"]
    for algorithm in (
        "current_stepwise_safe_deletion",
        "heaviest_safe_first",
        "weighted_greedy",
        "weighted_greedy_reverse_delete",
        "multistart_random_deletion",
        "preprocessed_highs_mip",
        "requirement_mask_dp",
    )
        algorithms[algorithm] === true || error("registered algorithm disabled: $algorithm")
    end
    algorithms["optional_second_solver"] == "UNAVAILABLE_NOT_INSTALLED" ||
        error("the optional second-solver declaration changed")
    controls = config["controls"]
    controls["dp_residual_requirement_limit"] == 22 || error("DP limit changed")
    controls["multistart_count"] == 32 || error("multi-start count changed")
    controls["multistart_seed"] == 20_260_827 || error("multi-start seed changed")
    controls["mip_seed"] == 0 || error("MIP seed changed")
    controls["mip_time_limit_seconds"] == 300.0 || error("MIP time limit changed")
    controls["mip_relative_gap_tolerance"] == 0.0 || error("relative gap changed")
    controls["mip_absolute_gap_tolerance"] == 0.0 || error("absolute gap changed")
    controls["mip_warm_start"] == "none" || error("MIP warm start changed")
    controls["highs_threads"] == 1 || error("HiGHS threads changed")
    controls["highs_parallel"] == "off" || error("HiGHS parallel mode changed")
    information = config["information_boundary"]
    for key in (
        "heldout_may_define_weights",
        "heldout_may_define_preprocessing",
        "heldout_may_define_algorithm_choice",
        "heldout_may_define_warm_start",
        "heldout_may_define_pruning_order",
        "heldout_may_define_objective",
        "terminal_annual_units_pooled",
        "raw_licensed_rows_written",
        "raw_licensed_rows_committed",
    )
        information[key] === false || error("information-boundary flag changed: $key")
    end
    information["heldout_reported_after_all_optimization"] === true || error(
        "held-out timing flag changed",
    )
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


function _amended_002_hashes()
    return Dict(
        path => _sha256_file(joinpath(REPOSITORY_ROOT, path)) for path in (
            REQUIRED_FILES...,
            AMENDMENT_001_FILES...,
            AMENDMENT_002_FILES...,
        )
    )
end


function _amended_003_hashes()
    return Dict(
        path => _sha256_file(joinpath(REPOSITORY_ROOT, path)) for path in (
            REQUIRED_FILES...,
            AMENDMENT_001_FILES...,
            AMENDMENT_002_FILES...,
            AMENDMENT_003_FILES...,
        )
    )
end


function _amended_004_hashes()
    return Dict(
        path => _sha256_file(joinpath(REPOSITORY_ROOT, path)) for path in (
            REQUIRED_FILES...,
            AMENDMENT_001_FILES...,
            AMENDMENT_002_FILES...,
            AMENDMENT_003_FILES...,
            AMENDMENT_004_FILES...,
        )
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
  "schema_version": "financial-algorithm-comparison-design-lock-v1",
  "experiment_id": "retrospective-financial-algorithm-comparison-v1",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "legacy_parent_financial_outcomes_preexist": true,
  "new_algorithm_comparison_outcomes_observed_before_lock": false,
  "licensed_rows_read_to_create_lock": false,
  "heldout_information_allowed_in_optimization": false,
  "terminal_annual_units_pooled": false,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end


function create_design_lock(config_path::AbstractString = DEFAULT_CONFIG)
    _validate(config_path)
    local_results = joinpath(STUDY_ROOT, "local_results")
    isdir(local_results) && !isempty(readdir(local_results)) && error(
        "cannot create the financial algorithm lock after local comparison results exist",
    )
    text = _render_lock(_hashes())
    mkpath(dirname(LOCK_PATH))
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, LOCK_PATH; force = true)
    println("created financial algorithm comparison design lock")
    return LOCK_PATH
end


function _original_aggregate(text::AbstractString)
    parsed = match(r"\"aggregate_sha256\": \"([0-9a-f]{64})\"", text)
    isnothing(parsed) && error("original financial comparison lock has no aggregate")
    return parsed.captures[1]
end


function _render_amendment_lock(hashes, original_lock_sha256, original_aggregate)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-algorithm-comparison-design-lock-amendment-v1",
  "experiment_id": "retrospective-financial-algorithm-comparison-v1",
  "amendment_id": "AMENDMENT_001",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "prior_design_lock_sha256": "$original_lock_sha256",
  "prior_design_lock_aggregate_sha256": "$original_aggregate",
  "licensed_rows_read_before_amendment": false,
  "parent_audit_started_before_amendment": false,
  "algorithm_outcome_observed_before_amendment": false,
  "scientific_design_changed": false,
  "repair_scope": "Julia 1.12 load-time module inclusion only",
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
    _validate(config_path)
    isfile(LOCK_PATH) || error("original financial comparison lock is absent")
    isfile(FAILURE_001_PATH) || error("execution failure record is absent")
    isfile(AMENDMENT_001_PATH) || error("amendment record is absent")
    local_results = joinpath(STUDY_ROOT, "local_results")
    isdir(local_results) && !isempty(readdir(local_results)) && error(
        "cannot lock amendment 001 after local comparison results exist",
    )
    original_text = read(LOCK_PATH, String)
    original_sha256 = _sha256_file(LOCK_PATH)
    failure = TOML.parsefile(FAILURE_001_PATH)
    failure["original_design_lock_sha256"] == original_sha256 || error(
        "failure record does not identify the original design lock",
    )
    for key in (
        "licensed_rows_read",
        "parent_audit_started",
        "algorithm_started",
        "comparison_outcome_observed",
        "local_result_artifact_written",
        "scientific_design_change_required",
    )
        failure[key] === false || error("failure record flag is not false: $key")
    end
    hashes = _amended_001_hashes()
    text = _render_amendment_lock(
        hashes,
        original_sha256,
        _original_aggregate(original_text),
    )
    temporary = AMENDMENT_LOCK_001_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, AMENDMENT_LOCK_001_PATH; force = true)
    println("created financial algorithm comparison amendment lock 001")
    return AMENDMENT_LOCK_001_PATH
end


function _render_amendment_lock_002(hashes, prior_lock_sha256, prior_aggregate)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-algorithm-comparison-design-lock-amendment-v1",
  "experiment_id": "retrospective-financial-algorithm-comparison-v1",
  "amendment_id": "AMENDMENT_002",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "prior_amendment_lock_sha256": "$prior_lock_sha256",
  "prior_amendment_lock_aggregate_sha256": "$prior_aggregate",
  "licensed_rows_read_before_amendment": true,
  "parent_audit_started_before_amendment": true,
  "algorithm_outcome_observed_before_amendment": false,
  "scientific_design_changed": false,
  "repair_scope": "committed source-certificate import plus licensed validation-profile recomputation and exact source-object checks",
  "annual_parent_replay_passed": false,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end


function create_design_lock_amendment_002(
    config_path::AbstractString = DEFAULT_CONFIG,
)
    _validate(config_path)
    for path in (
        LOCK_PATH,
        AMENDMENT_LOCK_001_PATH,
        FAILURE_002_PATH,
        AMENDMENT_002_PATH,
    )
        isfile(path) || error("required amendment-002 chain file is absent: $path")
    end
    local_results = joinpath(STUDY_ROOT, "local_results")
    isdir(local_results) && !isempty(readdir(local_results)) && error(
        "cannot lock amendment 002 after local comparison results exist",
    )
    prior_text = read(AMENDMENT_LOCK_001_PATH, String)
    prior_sha256 = _sha256_file(AMENDMENT_LOCK_001_PATH)
    failure = TOML.parsefile(FAILURE_002_PATH)
    failure["prior_design_lock_sha256"] == prior_sha256 || error(
        "failure 002 does not identify amendment lock 001",
    )
    for key in ("licensed_rows_read", "parent_audit_started")
        failure[key] === true || error("failure 002 flag is not true: $key")
    end
    for key in (
        "algorithm_started",
        "comparison_outcome_observed",
        "local_result_artifact_written",
        "raw_licensed_row_printed_or_written",
        "scientific_source_definition_changed",
    )
        failure[key] === false || error("failure 002 flag is not false: $key")
    end
    hashes = _amended_002_hashes()
    text = _render_amendment_lock_002(
        hashes,
        prior_sha256,
        _original_aggregate(prior_text),
    )
    temporary = AMENDMENT_LOCK_002_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, AMENDMENT_LOCK_002_PATH; force = true)
    println("created financial algorithm comparison amendment lock 002")
    return AMENDMENT_LOCK_002_PATH
end


function _render_amendment_lock_003(hashes, prior_lock_sha256, prior_aggregate)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-algorithm-comparison-design-lock-amendment-v1",
  "experiment_id": "retrospective-financial-algorithm-comparison-v1",
  "amendment_id": "AMENDMENT_003",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "prior_amendment_lock_sha256": "$prior_lock_sha256",
  "prior_amendment_lock_aggregate_sha256": "$prior_aggregate",
  "licensed_rows_have_previously_been_read": true,
  "licensed_rows_read_in_failed_attempt": false,
  "algorithm_outcome_observed_before_amendment": false,
  "scientific_design_changed": false,
  "repair_scope": "top-level TOML scoping for the unchanged registered weight-schedule list",
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end


function create_design_lock_amendment_003(
    config_path::AbstractString = DEFAULT_CONFIG,
)
    _validate(config_path)
    for path in (
        LOCK_PATH,
        AMENDMENT_LOCK_001_PATH,
        AMENDMENT_LOCK_002_PATH,
        FAILURE_003_PATH,
        AMENDMENT_003_PATH,
    )
        isfile(path) || error("required amendment-003 chain file is absent: $path")
    end
    local_results = joinpath(STUDY_ROOT, "local_results")
    isdir(local_results) && !isempty(readdir(local_results)) && error(
        "cannot lock amendment 003 after local comparison results exist",
    )
    prior_text = read(AMENDMENT_LOCK_002_PATH, String)
    prior_sha256 = _sha256_file(AMENDMENT_LOCK_002_PATH)
    failure = TOML.parsefile(FAILURE_003_PATH)
    failure["prior_design_lock_sha256"] == prior_sha256 || error(
        "failure 003 does not identify amendment lock 002",
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
        failure[key] === false || error("failure 003 flag is not false: $key")
    end
    hashes = _amended_003_hashes()
    text = _render_amendment_lock_003(
        hashes,
        prior_sha256,
        _original_aggregate(prior_text),
    )
    temporary = AMENDMENT_LOCK_003_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, AMENDMENT_LOCK_003_PATH; force = true)
    println("created financial algorithm comparison amendment lock 003")
    return AMENDMENT_LOCK_003_PATH
end


function _render_amendment_lock_004(hashes, prior_lock_sha256, prior_aggregate)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-algorithm-comparison-design-lock-amendment-v1",
  "experiment_id": "retrospective-financial-algorithm-comparison-v1",
  "amendment_id": "AMENDMENT_004",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "prior_amendment_lock_sha256": "$prior_lock_sha256",
  "prior_amendment_lock_aggregate_sha256": "$prior_aggregate",
  "licensed_rows_read_in_failed_attempt": true,
  "parent_source_reconstruction_started": true,
  "algorithm_outcome_observed_before_amendment": false,
  "scientific_design_changed": false,
  "repair_scope": "explicit held-out unit string returns plus direct regression tests",
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end


function create_design_lock_amendment_004(
    config_path::AbstractString = DEFAULT_CONFIG,
)
    _validate(config_path)
    for path in (
        LOCK_PATH,
        AMENDMENT_LOCK_001_PATH,
        AMENDMENT_LOCK_002_PATH,
        AMENDMENT_LOCK_003_PATH,
        FAILURE_004_PATH,
        AMENDMENT_004_PATH,
    )
        isfile(path) || error("required amendment-004 chain file is absent: $path")
    end
    local_results = joinpath(STUDY_ROOT, "local_results")
    isdir(local_results) && !isempty(readdir(local_results)) && error(
        "cannot lock amendment 004 after local comparison results exist",
    )
    prior_text = read(AMENDMENT_LOCK_003_PATH, String)
    prior_sha256 = _sha256_file(AMENDMENT_LOCK_003_PATH)
    failure = TOML.parsefile(FAILURE_004_PATH)
    failure["prior_design_lock_sha256"] == prior_sha256 || error(
        "failure 004 does not identify amendment lock 003",
    )
    for key in ("licensed_rows_read_this_attempt", "parent_source_reconstruction_started")
        failure[key] === true || error("failure 004 flag is not true: $key")
    end
    for key in (
        "algorithm_started",
        "comparison_outcome_observed",
        "local_result_artifact_written",
        "raw_licensed_row_printed_or_written",
        "scientific_design_change_required",
    )
        failure[key] === false || error("failure 004 flag is not false: $key")
    end
    hashes = _amended_004_hashes()
    text = _render_amendment_lock_004(
        hashes,
        prior_sha256,
        _original_aggregate(prior_text),
    )
    temporary = AMENDMENT_LOCK_004_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, AMENDMENT_LOCK_004_PATH; force = true)
    println("created financial algorithm comparison amendment lock 004")
    return AMENDMENT_LOCK_004_PATH
end


function verify_design_lock(config_path::AbstractString = DEFAULT_CONFIG)
    _validate(config_path)
    isfile(LOCK_PATH) || error("financial algorithm comparison design lock is absent")
    if isfile(AMENDMENT_LOCK_004_PATH)
        text = read(AMENDMENT_LOCK_004_PATH, String)
        hashes = _amended_004_hashes()
        for path in keys(hashes)
            occursin("\"$path\": \"$(hashes[path])\"", text) || error(
                "financial algorithm comparison amendment lock mismatch: $path",
            )
        end
        occursin("\"aggregate_sha256\": \"$(_aggregate(hashes))\"", text) ||
            error("financial algorithm comparison amendment aggregate mismatch")
        prior_sha256 = _sha256_file(AMENDMENT_LOCK_003_PATH)
        occursin("\"prior_amendment_lock_sha256\": \"$prior_sha256\"", text) ||
            error("financial comparison amendment 004 has a stale prior lock")
        occursin("\"algorithm_outcome_observed_before_amendment\": false", text) ||
            error("financial comparison amendment outcome-access declaration is invalid")
        return _aggregate(hashes)
    end
    if isfile(AMENDMENT_LOCK_003_PATH)
        text = read(AMENDMENT_LOCK_003_PATH, String)
        hashes = _amended_003_hashes()
        for path in keys(hashes)
            occursin("\"$path\": \"$(hashes[path])\"", text) || error(
                "financial algorithm comparison amendment lock mismatch: $path",
            )
        end
        occursin("\"aggregate_sha256\": \"$(_aggregate(hashes))\"", text) ||
            error("financial algorithm comparison amendment aggregate mismatch")
        prior_sha256 = _sha256_file(AMENDMENT_LOCK_002_PATH)
        occursin("\"prior_amendment_lock_sha256\": \"$prior_sha256\"", text) ||
            error("financial comparison amendment 003 has a stale prior lock")
        occursin("\"algorithm_outcome_observed_before_amendment\": false", text) ||
            error("financial comparison amendment outcome-access declaration is invalid")
        return _aggregate(hashes)
    end
    if isfile(AMENDMENT_LOCK_002_PATH)
        text = read(AMENDMENT_LOCK_002_PATH, String)
        hashes = _amended_002_hashes()
        for path in keys(hashes)
            occursin("\"$path\": \"$(hashes[path])\"", text) || error(
                "financial algorithm comparison amendment lock mismatch: $path",
            )
        end
        occursin("\"aggregate_sha256\": \"$(_aggregate(hashes))\"", text) ||
            error("financial algorithm comparison amendment aggregate mismatch")
        prior_sha256 = _sha256_file(AMENDMENT_LOCK_001_PATH)
        occursin("\"prior_amendment_lock_sha256\": \"$prior_sha256\"", text) ||
            error("financial comparison amendment 002 has a stale prior lock")
        occursin("\"algorithm_outcome_observed_before_amendment\": false", text) ||
            error("financial comparison amendment outcome-access declaration is invalid")
        occursin("\"annual_parent_replay_passed\": false", text) ||
            error("financial comparison amendment hides the annual replay limitation")
        return _aggregate(hashes)
    end
    if isfile(AMENDMENT_LOCK_001_PATH)
        text = read(AMENDMENT_LOCK_001_PATH, String)
        hashes = _amended_001_hashes()
        for path in keys(hashes)
            occursin("\"$path\": \"$(hashes[path])\"", text) || error(
                "financial algorithm comparison amendment lock mismatch: $path",
            )
        end
        occursin("\"aggregate_sha256\": \"$(_aggregate(hashes))\"", text) ||
            error("financial algorithm comparison amendment aggregate mismatch")
        original_sha256 = _sha256_file(LOCK_PATH)
        occursin("\"prior_design_lock_sha256\": \"$original_sha256\"", text) ||
            error("financial comparison amendment has a stale original lock")
        occursin("\"algorithm_outcome_observed_before_amendment\": false", text) ||
            error("financial comparison amendment outcome-access declaration is invalid")
        return _aggregate(hashes)
    end
    text = read(LOCK_PATH, String)
    hashes = _hashes()
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) || error(
            "financial algorithm comparison design lock mismatch: $path",
        )
    end
    occursin("\"aggregate_sha256\": \"$(_aggregate(hashes))\"", text) ||
        error("financial algorithm comparison aggregate lock mismatch")
    occursin("\"new_algorithm_comparison_outcomes_observed_before_lock\": false", text) ||
        error("financial comparison lock has an invalid outcome-access declaration")
    return _aggregate(hashes)
end


function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_algorithm_comparison_v1.jl --create|--amend-001|--amend-002|--amend-003|--amend-004|--check",
    )
    only(args) == "--create" && return create_design_lock()
    only(args) == "--amend-001" && return create_design_lock_amendment_001()
    only(args) == "--amend-002" && return create_design_lock_amendment_002()
    only(args) == "--amend-003" && return create_design_lock_amendment_003()
    only(args) == "--amend-004" && return create_design_lock_amendment_004()
    only(args) == "--check" && return println(
        "financial algorithm comparison design lock valid: $(verify_design_lock())",
    )
    error("unknown lock mode: $(only(args))")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialAlgorithmComparisonV1.main()
end
